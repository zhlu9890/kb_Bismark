package kb_Bismark::Util::BismarkMethylationExtractor;
use strict;

use kb_Bismark::Util::BismarkRunner;

use File::Spec;
use Archive::Zip qw( :ERROR_CODES );
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

sub extract {
  my ($self, $run_output_info, $input_configuration, $validated_params)=@_;
  my $extractor_output_info={};

  my $options = [qw/--no_header --multicore 4 --gzip --CX --bedGraph --output/, $run_output_info->{output_dir}, $run_output_info->{output_bam_file}];

  $self->{bismark_runner}->run('bismark_methylation_extractor', $options);

  my $extractor_output_dir=File::Spec->catfile($run_output_info->{output_dir}, $validated_params->{output_alignment_name});
  my $zip_file=$extractor_output_dir . ".zip";
  $extractor_output_info->{output_file}=[{
      path => $zip_file,
      name => $validated_params->{output_alignment_name},
      label => $validated_params->{output_alignment_name},
      description => "Methylation files extracted from Bismark bam output"
    }
  ];

  mkdir $extractor_output_dir;

  system("cp $run_output_info->{output_dir}/*.gz $extractor_output_dir");
  my $zip = Archive::Zip->new();
  unless ( $zip->writeToFileNamed($zip_file) == AZ_OK ) {
    die 'zip write error';
  }

  $extractor_output_info;
}

1;

