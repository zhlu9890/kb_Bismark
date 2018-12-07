package kb_Bismark::Util::BismarkRunner;
use strict;

use Bio::KBase::Exceptions;
use List::Util;

sub new {
  my ($class, $scratch) = @_;
  my $self = {};
  bless $self, $class;

  $self->{scratch}=$scratch;
  $self->{valid_commands}=[
    qw(bismark_genome_preparation bismark bismark_methylation_extractor)
  ];

  return $self;
}

sub run {
  my ($self, $command, $options, $cwd) = @_;
  $options||=[];

  unless (List::Util::any { $_ eq $command } @{$self->{valid_commands}}) {
    Bio::KBase::Exceptions::ArgumentValidationError->throw(
      error => "Invalid command: $command", 
      method_name => 'run',
    );
  }
  
  $command = [$command, @$options];' ' . join(' ', @$options);
  $cwd||=$self->{scratch};
  
  print 'In working directory: ' . $cwd . "\n";
  print 'Running: ' . join(' ', @$command) . "\n";

  my $exitCode=system(@$command);
  
  if ($exitCode == 0) {
    print 'Success, exit code was: ' . $exitCode . "\n";
  } else {
    Bio::KBase::Exceptions::ArgumentValidationError->throw(
      error => 'Error running command: ' . join(' ', @$command) . "\n" . 'Exit Code: ' . $exitCode, 
      method_name => 'run',
    );
  }
  return $exitCode;
}

1;
