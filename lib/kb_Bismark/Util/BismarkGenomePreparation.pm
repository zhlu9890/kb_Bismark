package kb_Bismark::Util::BismarkGenomePreparation;
use strict;

use Bio::KBase::Exceptions;
use kb_Bismark::Util::BismarkRunner;
use Workspace::WorkspaceClient;
use GenomeAnnotationAPI::GenomeAnnotationAPIServiceClient;
use DataFileUtil::DataFileUtilClient;
use AssemblyUtil::AssemblyUtilClient;
use Try::Tiny;
use File::Spec;
use File::Path qw(make_path);
use File::Basename;
use File::Copy;
use Data::Dumper;
$Data::Dumper::Terse = 1;

sub new {
  my ($class, @args) = @_;
  my $self = {};
  bless $self, $class;
  
  @{$self}{qw/scratch workspace_url callback_url srv_wiz_url context/}=@args;
  $self->{provenance}=$self->{context}->provenance;
  $self->{ws}=Workspace::WorkspaceClient->new($self->{workspace_url}, token => $self->{context}->token);
  $self->{bismark_runner}=kb_Bismark::Util::BismarkRunner->new($self->{scratch});

  return $self;
}

sub build_index {
  my ($self, $params)=@_;

  # validate the parameters and fetch assembly_info
  my $validated_params = $self->validate_params($params);
  my $assembly_info = $self->get_assembly_info($validated_params->{ref});
  
  # check the cache (keyed off of assembly_info)
  my $index_info = $self->get_cached_index($assembly_info, $validated_params);
  if ($index_info) {
    $index_info->{from_cache} = 1;
    $index_info->{pushed_to_cache} = 0;
  } else {
    # on a cache miss, build the index
    $index_info = $self->_build_index($assembly_info, $validated_params);
    $index_info->{from_cache} = 0
    # pushed_to_cache will be set in return from _build_index
  }
  $index_info->{assembly_ref} = $assembly_info->{ref};
  $index_info->{genome_ref} = $assembly_info->{genome_ref};

  return $index_info;
}

sub validate_params {
  my ($self, $params) = @_;
  # validate parameters; can do some processing here to produce validated params
  my $validated_params = {ref =>  undef};
  if (defined $params->{ref}) {
    $validated_params->{ref} = $params->{ref};
  } else {
	  Bio::KBase::Exceptions::ArgumentValidationError->throw(
      error => '"ref" field indicating either an assembly or genome is required.',
      method_name => '_validate_params',
    );
  }

  if ($params->{output_dir}) {
    $validated_params->{output_dir} = $params->{output_dir};
  } else {
    $validated_params->{output_dir} = File::Spec->catfile($self->{scratch}, 'bismark_index_' . time());
  }

  if (-e $validated_params->{output_dir}) {
    die "Output directory name specified (" . $validated_params->{output_dir} . ") already exists. Will not overwrite, so aborting.";
  }
  if ($params->{ws_for_cache}) {
    $validated_params->{ws_for_cache} = $params->{ws_for_cache};
  } else {
    print 'WARNING: bismark index if created will not be cached because "ws_for_cache" field not set' . "\n";
    $validated_params->{ws_for_cache} = undef;
  }
  
  return $validated_params;
}

sub get_assembly_info {
  my ($self, $ref) = @_;
  # given a ref to an assembly or genome, figure out the assembly and return its info
  my $info = $self->{ws}->get_object_info3({objects => [{ref => $ref}]})->{infos}[0];
  my $obj_type = $info->[2];
  if ($obj_type=~/^(?:KBaseGenomeAnnotations\.Assembly|KBaseGenomes\.ContigSet)/) {
    return {info => $info, ref => $ref, genome_ref => undef};
  }

  if ($obj_type=~/^KBaseGenomes\.Genome/) {
    # we need to get the assembly for this genome
    my $ga = GenomeAnnotationAPI::GenomeAnnotationAPIServiceClient->new($self->{srv_wiz_url}, token => $self->{context}->token);
    my $assembly_ref = $ga->get_assembly({ref => $ref});
    # using the path ensures we can access the assembly even if we don't have direct access
    my $ref_path = $ref . ';' . $assembly_ref;
    my $info = $self->{ws}->get_object_info3({objects => [{ref => $ref_path}]})->{infos}[0];
    return {info => $info, ref => $ref_path, genome_ref => $ref};
  }
  Bio::KBase::Exceptions::ArgumentValidationError->throw(
    error => 'Input object was not of type: Assembly, ContigSet or Genome. Cannot build bismark Index.',
    method_name => 'get_assembly_info'
  );
}

sub get_cached_index{
  my ($self, $assembly_info, $validated_params) = @_;
  my $return;
  try {
    # note: list_reference_objects does not yet support reference paths, so we need to call
    # with the direct reference.  So we won't get a cache hit if you don't have direct access
    # to the assembly object right now (although you can still always build the assembly object)
    # Once this call supports paths, this should be changed to set ref = assembly_info['ref']
    my $info = $assembly_info->{info};
    my $ref = $info->[6] . '/' . $info->[0] . '/' . $info->[4];
    my $objs = $self->{ws}->list_referencing_objects([{ref => $ref}])->[0];

    # iterate through each of the objects that reference the assembly
    my $bismark_indexes = [];
    foreach my $o (@$objs) {
      #if ($o->[2]=~/^KBaseBSSeq\.Bismark2Index/) {
      if ($o->[2]=~/^KBaseRNASeq\.Bowtie2IndexV2/) {
        push @$bismark_indexes, $o;
      }
    }

    # Nothing refs this assembly, so cache miss
    if (scalar @$bismark_indexes == 0) {
      return;
    }

    # if there is more than one hit, get the most recent one
    # (obj_info[3] is the save_date timestamp (eg 2017-05-30T22:56:49+0000), so we can sort on that)
    $bismark_indexes=[sort {$a->[3] cmp $b->[3]} @$bismark_indexes];
    my $bismark_index_info = $bismark_indexes->[-1];
    my $index_ref = $bismark_index_info->[6] . '/' . $bismark_index_info->[0] . '/' . $bismark_index_info->[4];

    # get the object data
    my $index_obj_data = $self->{ws}->get_objects2({objects => [{ref => $index_ref}]})->{data}[0]{data};

    # download the handle object
    make_path($validated_params->{output_dir});

    my $dfu = DataFileUtil::DataFileUtilClient->new($self->{callback_url});
    $dfu->shock_to_file({
        file_path => File::Spec->catfile($validated_params->{output_dir}, 'bismark_index.tar.gz'),
        handle_id => $index_obj_data->{handle}{hid},
        unpack => 'unpack'
      }
    );
    print 'Cache hit: '. "\n";
    print Dumper($index_obj_data);
    $return={
      output_dir => $validated_params->{output_dir},
      index_files_basename => $index_obj_data->{index_files_basename}
    };
  } catch {
    my ($e)=@_;
    # if we fail in saving the cached object, don't worry
    print 'WARNING: exception encountered when trying to lookup in cache:' . "\n";
    print $e . "\n";
    print 'END WARNING: exception encountered when trying to lookup in cache.' . "\n";
    $return=undef;
  };
  
  $return;
}

sub put_cached_index {
  my ($self, $assembly_info, $index_files_basename, $output_dir, $ws_for_cache) = @_;
  unless ($ws_for_cache) {
    print 'WARNING: bismark index cannot be cached because "ws_for_cache" field not set' . "\n";
    return 0;
  }
  
  my $return=0;
  try {
    my $dfu = DataFileUtil::DataFileUtilClient->new($self->{callback_url});
    my $result = $dfu->file_to_shock({
        file_path => $output_dir,
        make_handle => 1,
        pack => 'targz'
      }
    );

    my $bismark_index = {
      handle => $result->{handle}, 
      size => $result->{size},
      assembly_ref => $assembly_info->{ref},
      index_files_basename => $index_files_basename
    };
    
    my $ws = $self->{ws};
    my $save_params = {
      objects => [{
          hidden => 1,
          provenance => $self->{provenance},
          name => basename($output_dir),
          data => $bismark_index,
          #type => 'KBaseBSSeq.Bismark2Index'
          type => 'KBaseRNASeq.Bowtie2IndexV2'
        }
      ]
    };
    $ws_for_cache=~s/^\s*(\S+)\s*$/$1/;
    if ($ws_for_cache=~/^\d+$/) {
      $save_params->{id} = $ws_for_cache;
    } else {
      $save_params->{workspace} = $ws_for_cache;
    }
    my $save_result = $ws->save_objects($save_params);
    print 'BismarkIndex cached to: ' . "\n";
    print Dumper($save_result->[0]);
    $return=1;
  } catch {
    my ($e)=@_;
    # if we fail in saving the cached object, don't worry
    print 'WARNING: exception encountered when trying to cache the index files:' . "\n";
    print $e . "\n";
    print 'END WARNING: exception encountered when trying to cache the index files' . "\n";
    $return=0;
  };
  $return;
}


sub _build_index {
  my ($self, $assembly_info, $validated_params) = @_;
  # get the assembly as a fasta file using AssemblyUtil
  my $au = AssemblyUtil::AssemblyUtilClient->new($self->{callback_url});
  my $fasta_info = $au->get_assembly_as_fasta({ref => $assembly_info->{ref}});

  # make the target destination folder (check again it wasn't created yet)
  if (-e $validated_params->{output_dir}) {
    die 'Output directory name specified (' . $validated_params->{output_dir} . ') already exists. Will not overwrite, so aborting.';
  }
  make_path($validated_params->{output_dir});

  # configure the command line args and run it
  my $cli_params = $self->build_cli_params($fasta_info->{path}, $fasta_info->{assembly_name}, $validated_params);
  $self->{bismark_runner}->run('bismark_genome_preparation', $cli_params);
  my $index_info = {
    output_dir => $validated_params->{output_dir},
    index_files_basename => $fasta_info->{assembly_name}
  };

  # cache the result, mark if it worked or not
  my $cache_success = $self->put_cached_index(
    $assembly_info,
    $fasta_info->{assembly_name},
    $validated_params->{output_dir},
    $validated_params->{ws_for_cache}
  );
  $index_info->{pushed_to_cache}=$cache_success ? 1 : 0;

  return $index_info;
}


sub build_cli_params {
  my ($self, $fasta_file_path, $index_files_basename, $validated_params) = @_;
  move($fasta_file_path, $validated_params->{output_dir});

  my $cli_params = [];

  # run using bowtie2;
  push @$cli_params, '--bowtie2', '--genomic_composition';

  # positional args: <path_to_genome_folder>
  push @$cli_params, $validated_params->{output_dir};

  return $cli_params;
}

1;
