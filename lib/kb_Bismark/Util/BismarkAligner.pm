package kb_Bismark::Util::BismarkAligner;
use strict;

use kb_Bismark::Util::BismarkGenomePreparation;
use kb_Bismark::Util::BismarkRunner;

use ReadsUtils::ReadsUtilsClient;
use ReadsAlignmentUtils::ReadsAlignmentUtilsClient;
use DataFileUtil::DataFileUtilClient;

use KBaseReport::KBaseReportClient;
use Workspace::WorkspaceClient;
use SetAPI::SetAPIServiceClient;
use KBParallel::KBParallelClient;
#use installed_clients::kb_QualiMapClient;

use Config::IniFiles;
use JSON;
use File::Temp ();
use File::Spec;
use File::Basename;
use File::Slurp;
use Storable ();
use Data::Dumper;
use List::Util qw(any);
$Data::Dumper::Terse = 1;

sub new {
  my ($class, @args) = @_;
  my $self = {};
  bless $self, $class;

  @{$self}{qw/scratch workspace_url callback_url srv_wiz_url context/}=@args;
  $self->{provenance}=$self->{context}->provenance;

  $self->{my_version} = 'release';
  if (scalar @{$self->{provenance}} > 0) {
    if (exists $self->{provenance}[0]{subactions}) {
      $self->{my_version}=$self->get_version_from_subactions('kb_Bismark', $self->{provenance}[0]{subactions});
    }
  }
  print('Running kb_Bismark version = ' . $self->{my_version}) . "\n";

  $self->{ws}= Workspace::WorkspaceClient->new($self->{workspace_url}, token => $self->{context}->token);
  $self->{bismark_runner} = kb_Bismark::Util::BismarkRunner->new($self->{scratch});
  $self->{parallel_runner} = KBParallel::KBParallelClient->new($self->{callback_url});
  #$self->{qualimap} = installed_clients::kb_QualiMapClient->new($self->{callback_url});

  return $self;
}

sub get_version_from_subactions {
  my ($self, $module_name, $subactions)=@_;
  my $return='release';
  if (defined $subactions) {
    foreach my $sa (@$subactions) {
      if (defined $sa->{name} && $sa->{name} eq $module_name) {
        if ($sa->{commit} eq 'local-docker-image') {
          $return='dev';
        } elsif ($sa->{commit}=~m/[a-fA-F0-9]{40}$/) {
          $return=$sa->{commit};
        }
      }
    }
  }
  $return;
}

sub align {
  my ($self, $params)=@_;
  my $validated_params = $self->validate_params($params);
  my $input_info = $self->determine_input_info($validated_params->{input_ref});

  my $assembly_or_genome_ref = $validated_params->{assembly_or_genome_ref};

  my $return;
  if ($input_info->{run_mode} eq 'single_library') {
    $validated_params->{output_alignment_name}||=$input_info->{info}[1] . ($validated_params->{output_alignment_suffix} || "_bismarkAlignment");

    $return = $self->single_reads_lib_run(
      $input_info,
      $assembly_or_genome_ref,
      $validated_params
    );
  } elsif ($input_info->{run_mode} eq 'sample_set') {
    my $reads = $self->fetch_reads_refs_from_sampleset($input_info->{ref}, $input_info->{info}, $validated_params);
    print 'Running on set of reads=' . "\n";
    print Dumper($reads);
    my $tasks = [];
    foreach my $r (@$reads) {
      push @$tasks, $self->build_single_execution_task($r->{ref}, $params, $r->{alignment_output_name}, $r->{condition});
    }
    
    my $batch_run_params = {
      tasks   => $tasks,
      runner  => 'parallel',
      max_retries => 2
    };
    if (defined $validated_params->{concurrent_local_tasks}) {
      $batch_run_params->{concurrent_local_tasks} = $validated_params->{concurrent_local_tasks};
    }
    if (defined $validated_params->{concurrent_njsw_tasks}) {
      $batch_run_params->{concurrent_njsw_tasks} = $validated_params->{concurrent_njsw_tasks};
    }
    my $results = $self->parallel_runner->run_batch($batch_run_params);
    print 'Batch run results=' . "\n";
    print Dumper($results);
    $return = $self->process_batch_result($results, $validated_params, $reads, $input_info->{info});
  }
  $return or die 'Improper run mode';
}

sub build_single_execution_task {
  my ($self, $reads_lib_ref, $params, $output_name, $condition)=@_;
  my $task_params = Storeable::dclone($params);
  $task_params->{input_ref} = $reads_lib_ref;
  $task_params->{output_alignment_name} = $output_name;
  $task_params->{create_report} = 0;
  $task_params->{condition_label} = $condition;
  
  my $result={
    module_name => 'kb_Bismark',
    function_name => 'align_reads_to_assembly_app',
    version => $self->{my_version},
    parameters => $task_params
  };
}

sub single_reads_lib_run {
  my ($self, $read_lib_info, $assembly_or_genome_ref, $validated_params, $bismark_index_info) = @_;

  my $create_report=$validated_params->{create_report};
  
  #run on one reads
  
  # download reads and prepare any bismark index files
  my $input_configuration = $self->prepare_single_run($read_lib_info, $assembly_or_genome_ref, $bismark_index_info, $validated_params->{output_workspace});
  
  # run the actual program
  my $run_output_info = $self->run_bismark_align_cli($input_configuration, $validated_params);
  
  # process the result and save the output
  my $upload_results = $self->save_read_alignment_output($run_output_info, $input_configuration, $validated_params);
  $run_output_info->{upload_results} = $upload_results;
  
  my $report_info;
  if ($create_report) {
    $report_info = $self->create_report_for_single_run($run_output_info, $input_configuration, $validated_params);
  }
  
  $self->clean($run_output_info);
  
  my $return={
    alignment_ref => $upload_results->{obj_ref},
    report_ref => $report_info ? $report_info->{ref} : undef,
    report_name => $report_info ? $report_info->{name} : undef
  };
  #my $return={
  #  output_info => $run_output_info, 
  #  report_info => $report_info,
  #};
}

sub build_bismark_index {
  my ($self, $assembly_or_genome_ref, $ws_for_cache) = @_;
  my $bismarkGenomePreparation = kb_Bismark::Utils::BismarkGenomePreparation->new(
    $self->{scratch}, 
    $self->{workspace_url},
    $self->{callback_url},
    $self->{srv_wiz_url},
    $self->{context}
  );
  
  my $return=$bismarkGenomePreparation->get_index(
    {ref => $assembly_or_genome_ref, ws_for_cache => $ws_for_cache}
  );
}

sub prepare_single_run {
  my ($self, $input_info, $assembly_or_genome_ref, $bismark_index_info, $ws_for_cache) = @_;
  # Given a reads ref and an assembly, setup the bismark index
  # first setup the bidmark index of the assembly
  unless ($bismark_index_info) {
    my $indexer = kb_Bismark::Util::BismarkGenomePreparation->new(
      $self->{scratch},
      $self->{workspace_url},
      $self->{callback_url},
      $self->{srv_wiz_url},
      $self->{context}
    );
    $bismark_index_info = $indexer->build_index({
        ref => $assembly_or_genome_ref,
        ws_for_cache => $ws_for_cache
      }
    );
  }
  my $input_configuration = {
    bismark_index_info => $bismark_index_info
  };

  # next download the reads
  my $read_lib_ref = $input_info->{ref};
  my $read_lib_info = $input_info->{info};
  my $reads_params = {
    read_libraries => [$read_lib_ref],
    interleaved => "false",
    gzipped =>  undef
  };
  
  my $ru = ReadsUtils::ReadsUtilsClient->new($self->{callback_url});
  my $rr = $ru->download_reads($reads_params);
  my $reads = $rr->{files};

  $input_configuration->{reads_lib_type} = [split(/\./, $self->get_type_from_obj_info($read_lib_info))]->[1];
  $input_configuration->{reads_files} = $reads->{$read_lib_ref};
  $input_configuration->{reads_lib_ref} = $read_lib_ref;
  
  $input_configuration;
}

sub run_bismark_align_cli {
  my ($self, $input_configuration, $validated_params) = @_;
  print '======== input_configuration =====' . "\n";
  print Dumper($input_configuration);

  my $options = [qw/--bowtie2 --quiet --basename/, $validated_params->{output_alignment_name}];
  my $run_output_info = {};

  # set the bismark index location
  my $bismark_index_info=$input_configuration->{bismark_index_info};
  my $bismark_index_dir = File::Spec->catfile($bismark_index_info->{output_dir}, $bismark_index_info->{assembly_name});
  push @$options, $bismark_index_dir;

  # set the input reads
  if ($input_configuration->{reads_lib_type} eq 'SingleEndLibrary') {
    push $options, $input_configuration->{reads_files}{files}{fwd};
    $run_output_info->{library_type} = 'single_end';
  } elsif ($input_configuration->{reads_lib_type} eq 'PairedEndLibrary') {
    push $options, '-1', $input_configuration->{reads_files}{files}{fwd};
    push $options, '-2', $input_configuration->{reads_files}{files}{rev};
    $run_output_info->{library_type} = 'paired_end';
  }

  # setup the output file name
  my $output_dir = File::Spec->catfile($self->{scratch}, 'bismark_alignment_output_' . time());
  my $output_bam_file = File::Spec->catfile($output_dir, $validated_params->{output_alignment_name} . ($input_configuration->{reads_lib_type} eq 'PairedEndLibrary' ? '_pe' : '') . '.bam');
  $run_output_info->{output_bam_file} = $output_bam_file;
  unshift @$options, '-o', $output_dir;
  $run_output_info->{output_dir} = $output_dir;

  # parse all the other parameters
  if (defined $validated_params->{qual}) {
    unshift @$options, '--' . $validated_params->{qual} . '-quals';
  }

  if ($validated_params->{lib_type}) {
    unshift @$options, '--' . $validated_params->{lib_type};
  }

  if (defined $validated_params->{minins}) {
    unshift @$options, '-I', $validated_params->{minins}; 
  }

  if (defined $validated_params->{maxins}) {
    unshift @$options, '-X', $validated_params->{maxins}; 
  }

  $self->{bismark_runner}->run('bismark', $options);

  $run_output_info;
}

sub save_read_alignment_output {
  my ($self, $run_output_info, $input_configuration, $validated_params) = @_;
  my $rau = ReadsAlignmentUtils::ReadsAlignmentUtilsClient->new($self->{callback_url});
  my $destination_ref = $validated_params->{output_workspace} . '/' . $validated_params->{output_alignment_name};
  my $condition = $validated_params->{condition_label} || 'unknown';
  my $upload_params = {
    file_path => $run_output_info->{output_bam_file},
    destination_ref => $destination_ref,
    read_library_ref => $input_configuration->{reads_lib_ref},
    assembly_or_genome_ref => $validated_params->{assembly_or_genome_ref},
    condition => $condition
  };
  my $upload_results = $rau->upload_alignment($upload_params);
}

sub clean {
  my ($self, $run_output_info):
  #Not really necessary on a single run, but if we are running multiple local subjobs, we should clean up files that have already been saved back up to kbase
}

sub create_report_for_single_run {
  my ($self, $run_output_info, $input_configuration, $validated_params) = @_;

  #my $qualimap_report = $self->{qualimap}->run_bamqc({
  #    input_ref => $run_output_info->{upload_results}{obj_ref}
  #  }
  #);
  #my $qc_result_zip_info = $qualimap_report->{qc_result_zip_info};

  my $dfu=DataFileUtil::DataFileUtilClient->new($self->{callback_url});

  # create report
  my $report_text = "Ran on a single reads library.\n\n";
  my $alignment_info = $self->get_obj_info($run_output_info->{upload_results}{obj_ref});
  $report_text .= "Created ReadsAlignment: " . $alignment_info->[1] . "\n";
  $report_text .= "                        " . $run_output_info->{upload_results}{obj_ref} . "\n";
  my $html_folder=File::Spec->catfile($run_output_info->{output_dir}, 'html');
  mkdir $html_folder;
  system("cd $run_output_info->{output_dir} && bismark2report && mv $run_output_info->{output_dir}/$validated_params->{output_alignment_name}_*_report.html $html_folder");
  my $fh;
  open $fh, ">", "$html_folder/index.html" or die "can't open $html_folder/index.html: $!";
  print $fh '<html style="height: 100%;"><body style="margin: 0; padding: 0; height: 100%; box-sizing: border-box;"><div id="body">my report</div></body></html>';
  close $fh;

  my $shock = $dfu->file_to_shock({
      file_path => $html_folder,
      make_handle => 0,
      pack => 'zip'
    }
  );

  my $output_html_files=[{
      shock_id => $shock->{shock_id},
      name => 'index.html',
      label => 'html files',
      description => 'HTML files',
    }];

  my $kbr = KBaseReport::KBaseReportClient->new($self->{callback_url});
  my $report_info = $kbr->create_extended_report({
      message => $report_text,
      objects_created => [{
          ref => $run_output_info->{upload_results}{obj_ref},
          description => 'ReadsAlignment'
        }
      ],
      report_object_name => 'kb_Bismark_' . time(),
      #direct_html => $html,
      #direct_html_link_index => undef,
      direct_html_link_index => 0,
      html_links => $output_html_files,
      #html_links => [{
      #    shock_id => $qc_result_zip_info->{shock_id},
      #    name => $qc_result_zip_info->{index_html_file_name},
      #    label => $qc_result_zip_info->{name}
      #  }
      #],
      workspace_name => $validated_params->{output_workspace}
    }
  );

  $report_info;
}

sub process_batch_result {
  my ($self, $batch_result, $validated_params, $reads, $input_set_info) = @_;
  
  my $n_jobs = scalar @{$batch_result->{results}};
  my $n_success = 0;
  my $n_error = 0;
  my $ran_locally = 0;
  my $ran_njsw = 0;

  # reads alignment set items
  my $items = [];
  my $objects_created = [];

  foreach my $k (0 .. $n_jobs) {
    my $job = $batch_result->{results}[$k];
    my $result_package = $job->{result_package};
    if ($job->{is_error}) {
      $n_error += 1;
    } else {
      $n_success += 1;
      my $output_info = $result_package->{result}[0]{output_info};
      my $ra_ref = $output_info->{upload_results}{obj_ref};
      # Note: could add a label to the alignment here?
      push @$items, {ref => $ra_ref, label => $reads->[$k]{condition}};
      push @$objects_created, {ref => $ra_ref};

      if ($result_package->{run_context}{location} eq 'local') {
        $ran_locally += 1;
      } elsif ($result_package->{run_context}{location} eq 'njsw') {
        $ran_njsw += 1;
      }
    }
  }

  # Save the alignment set
  my $alignment_set_data = {description => '', items => $items};
  my $alignment_set_save_params = {
    data => $alignment_set_data,
    workspace => $validated_params->{output_workspace},
    output_object_name => $input_set_info->[1] . ($validated_params->{output_alignment_suffix} || "_bismarkAlignment")
  };
  
  my $set_api = SetAPI::SetAPIServiceClient->new($self->{srv_wiz_url});
  my $save_result = $set_api->save_reads_alignment_set_v1($alignment_set_save_params);
  print 'Saved ReadsAlignment=' . "\n";
  print Dumper($save_result);
  push @$objects_created, {ref => $save_result->{set_ref}, description => 'Set of all reads alignments generated'};
  my $set_name = $save_result->{set_info}[1];

  # run qualimap
  #qualimap_report = self.qualimap.run_bamqc({'input_ref': save_result['set_ref']})
  #qc_result_zip_info = qualimap_report['qc_result_zip_info']

  # create the report
  my $report_text = "Ran on SampleSet or ReadsSet.\n\n";
  $report_text .= 'Created ReadsAlignmentSet: ' . $set_name . "\n\n";
  $report_text .= 'Total ReadsLibraries = ' . $n_jobs . "\n";
  $report_text .= '        Successful runs = ' . $n_success . "\n";
  $report_text .= '            Failed runs = ' . $n_error . "\n";
  $report_text .= '       Ran on main node = ' . $ran_locally . "\n";
  $report_text .= '   Ran on remote worker = ' . $ran_njsw . "\n\n";

  print 'Report text=' . "\n";
  print $report_text;

  my $kbr = KBaseReport::KBaseReportClient->new($self->{callback_url});
  my $report_info = $kbr->create_extended_report({
      message => $report_text,
      objects_created => $objects_created,
      report_object_name => 'kb_Bismark',
      #report_object_name => 'kb_Bismark_' + str(uuid.uuid4()),
      direct_html_link_index => undef,
      html_links => [],
      #html_links => [{'shock_id': qc_result_zip_info['shock_id'],
      #    name => qc_result_zip_info['index_html_file_name'],
      #    label => qc_result_zip_info['name']}],
      workspace_name => $validated_params->{output_workspace}
    }
  );
  
  my $return = {
    report_info => {
      report_name => $report_info->{name}, 
      report_ref => $report_info->{ref},
      batch_output_info => $batch_result
    }
  };
}

sub validate_params {
  my ($self, $params) = @_;
  my $validated_params = {};
  
  my $required_string_fields = [qw/input_ref assembly_or_genome_ref output_workspace/];
  
  foreach my $field (@$required_string_fields) {
    if ($params->{$field}) {
      $validated_params->{$field} = $params->{$field};
    } else {
      die qq("$field" field required to run bismark aligner app);
    }
    
    my $optional_fields = [qw/lib_type mismatch length qual minins maxins output_alignment_suffix output_alignment_name/];
    foreach my $field (@$optional_fields) {
      if (defined $params->{$field}) {
        $validated_params->{$field} = $params->{$field};
      }
    }
    
    $validated_params->{create_report} = 1;
    if (defined $params->{create_report}) {
      $validated_params->{create_report}=$params->{create_report};
    }
    
    if (defined $params->{concurrent_local_tasks}) {
      $validated_params->{concurrent_local_tasks}=$params->{concurrent_local_tasks};
    }
    if (defined $params->{concurrent_njsw_tasks}) {
      $validated_params->{concurrent_njsw_tasks}=$params->{concurrent_njsw_tasks};
    }
  }
  $validated_params;
}

sub fetch_reads_refs_from_sampleset {
  my ($self, $ref, $info, $validated_params)=@_;
  my $obj_type = $self->get_type_from_obj_info($info);
  my $refs = [];
  my $refs_for_ws_info = [];
  if (any { $_ eq "KBaseSets.ReadsSet" || $_ eq "KBaseRNASeq.RNASeqSampleSet" } @$obj_type) {
    print "Looking up reads references in ReadsSet object" . "\n";
    my $set_api = SetAPI::SetAPIServiceClient->new($self->{srv_wiz_url});
    my $reads_set = $set_api->get_reads_set_v1({
        ref => $ref,
        include_item_info => 0,
        include_set_item_ref_paths=> 1
      }
    );

    foreach my $reads (@{$reads_set->{data}{items}}) {
      push @$refs, {
        ref => $reads->{ref_path},
        condition => $reads->{label}
      };
      push @$refs_for_ws_info, {
        ref => $reads->{ref_path}
      };
    }
  } else {
    die "Unable to fetch reads reference from object $ref which is a $obj_type";
    
    # get object info so we can name things properly
    my $infos = $self->{ws}->get_object_info3({objects => $refs_for_ws_info})->{infos};

    my $ext=$validated_params->{output_alignment_suffix};
    defined $ext and $ext=~s/ //g;
    my $name_ext=$ext || '_alignment';

    my $unique_name_lookup = {};
    foreach my $k (0 .. $#$refs) {
      $refs->[$k]{info} = $infos->{k};
      my $name = $infos->[$k][1];
      unless (exists $unique_name_lookup->{$name}) {
        $unique_name_lookup->{$name}=1;
      } else {
        $unique_name_lookup->{$name} += 1;
        $name = $name . '_' . $unique_name_lookup->{$name}
      }
      $name .= $name_ext;
      $refs->[$k]{alignment_output_name} = $name;
    }
  }
  
  return $refs;
}
  
sub determine_input_info {
  my ($self, $input_ref)=@_;
  # get info on the input_ref object and determine if we run once or run on a set 
  my $info = $self->get_obj_info($input_ref);
  my $obj_type = $self->get_type_from_obj_info($info);
  if ( any {$obj_type eq $_} qw(KBaseAssembly.PairedEndLibrary KBaseAssembly.SingleEndLibrary KBaseFile.PairedEndLibrary KBaseFile.SingleEndLibrary)) {
    return {run_mode => 'single_library', info => $info, ref => $input_ref};
  }
  
  if ($obj_type eq 'KBaseRNASeq.RNASeqSampleSet') {
    return {run_mode => 'sample_set', info => $info, ref => $input_ref};
  }
  if ($obj_type eq 'KBaseSets.ReadsSet') {
    return {run_mode => 'sample_set', info => $info, ref => $input_ref};
  }
  
  die 'Object type of input_ref is not valid, was: ' . $obj_type;
}

sub get_type_from_obj_info {
  my ($self, $info) = @_;
  return [split(/-/, $info->[2])]->[0];
}

sub get_obj_info {
  my ($self, $ref) = @_;
  return $self->{ws}->get_object_info3({
      objects => [{ref => $ref}]
    }
  )->{infos}[0];
}

1;
