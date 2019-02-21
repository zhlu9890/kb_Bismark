package kb_Bismark::Util::BismarkMethylationExtractor;
use strict;

use kb_Bismark::Util::BismarkRunner;

use Cwd;
use File::Spec;
use File::Basename;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
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

  my $zip_file=File::Spec->catfile($run_output_info->{output_dir}, $validated_params->{output_alignment_name}. ".zip");
  $extractor_output_info->{output_file}=[{
      path => $zip_file,
      name => basename($zip_file),
      label => basename($zip_file),
      description => "Methylation files extracted from Bismark bam output"
    }
  ];

  my $cwd=cwd();
  chdir $run_output_info->{output_dir};

  my @output_files=glob("*.gz");
  system("zip $zip_file @output_files") == 0 or die "Unable to create zip file";

  chdir $cwd;

  $extractor_output_info;
}

1;

