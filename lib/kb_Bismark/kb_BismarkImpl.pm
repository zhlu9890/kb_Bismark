package kb_Bismark::kb_BismarkImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = '0.0.1';
our $GIT_URL = 'git@github.com:zhlu9890/kb_Bismark.git';
our $GIT_COMMIT_HASH = '981b57849f4c97842ce57d41e4dbc13567ec3c0a';

=head1 NAME

kb_Bismark

=head1 DESCRIPTION

A KBase module: kb_Bismark

=cut

#BEGIN_HEADER
use Bio::KBase::AuthToken;
use Config::IniFiles;
use kb_Bismark::Util::BismarkGenomePreparation;
use kb_Bismark::Util::BismarkAligner;
use kb_Bismark::Util::BismarkMethylationExtractor;
use kb_Bismark::Util::BismarkRunner;
use Data::Dumper;
$Data::Dumper::Terse = 1;
#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR
    my $config_file = $ENV{ KB_DEPLOYMENT_CONFIG };
    my $cfg = Config::IniFiles->new(-file=>$config_file);
    $self->{callback_url}= $ENV{SDK_CALLBACK_URL};
    foreach my $service (qw/scratch workspace-url srv-wiz-url/) {
      my $name=$service; $name=~s/\-/_/g;
      $self->{$name} = $cfg->val(kb_Bismark => $service);
    }
    die "no workspace-url defined" unless $self->{workspace_url};
    $self->{context}=$kb_Bismark::kb_BismarkServer::CallContext;
                    
    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 genome_preparation

  $result = $obj->genome_preparation($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Bismark.preparationParams
$result is a kb_Bismark.preparationResult
preparationParams is a reference to a hash where the following keys are defined:
	assembly_or_genome_ref has a value which is a string
	output_dir has a value which is a string
	ws_for_cache has a value which is a string
preparationResult is a reference to a hash where the following keys are defined:
	output_dir has a value which is a string
	from_cache has a value which is a kb_Bismark.boolean
	pushed_to_cache has a value which is a kb_Bismark.boolean
boolean is an int

</pre>

=end html

=begin text

$params is a kb_Bismark.preparationParams
$result is a kb_Bismark.preparationResult
preparationParams is a reference to a hash where the following keys are defined:
	assembly_or_genome_ref has a value which is a string
	output_dir has a value which is a string
	ws_for_cache has a value which is a string
preparationResult is a reference to a hash where the following keys are defined:
	output_dir has a value which is a string
	from_cache has a value which is a kb_Bismark.boolean
	pushed_to_cache has a value which is a kb_Bismark.boolean
boolean is an int


=end text



=item Description



=back

=cut

sub genome_preparation
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to genome_preparation:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genome_preparation');
    }

    my $ctx = $kb_Bismark::kb_BismarkServer::CallContext;
    my($result);
    #BEGIN genome_preparation
    print 'Running genome_preparation() with params=' . "\n";
    print Dumper($params);
    my $indexer=kb_Bismark::Util::BismarkGenomePreparation->new(
      @{$self}{qw/scratch workspace_url callback_url srv_wiz_url/}, $ctx, 
    );
    $result=$indexer->build_index($params);
    #END genome_preparation
    my @_bad_returns;
    (ref($result) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"result\" (value was \"$result\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to genome_preparation:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genome_preparation');
    }
    return($result);
}




=head2 bismark

  $result = $obj->bismark($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Bismark.bismarkParams
$result is a kb_Bismark.bismarkResult
bismarkParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
	assembly_or_genome_ref has a value which is a string
	output_workspace has a value which is a string
	lib_type has a value which is a string
	mismatch has a value which is an int
	length has a value which is an int
	qual has a value which is a string
	minins has a value which is an int
	maxins has a value which is an int
bismarkResult is a reference to a hash where the following keys are defined:
	alignment_ref has a value which is a string
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is a kb_Bismark.bismarkParams
$result is a kb_Bismark.bismarkResult
bismarkParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
	assembly_or_genome_ref has a value which is a string
	output_workspace has a value which is a string
	lib_type has a value which is a string
	mismatch has a value which is an int
	length has a value which is an int
	qual has a value which is a string
	minins has a value which is an int
	maxins has a value which is an int
bismarkResult is a reference to a hash where the following keys are defined:
	alignment_ref has a value which is a string
	report_name has a value which is a string
	report_ref has a value which is a string


=end text



=item Description



=back

=cut

sub bismark
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to bismark:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'bismark');
    }

    my $ctx = $kb_Bismark::kb_BismarkServer::CallContext;
    my($result);
    #BEGIN bismark
    print 'Running bismark() with params=' . "\n";
    print Dumper($params);
    my $aligner=kb_Bismark::Util::BismarkAligner->new(
      @{$self}{qw/scratch workspace_url callback_url srv_wiz_url/}, $ctx, 
    );
    $result=$aligner->align($params);
    #END bismark
    my @_bad_returns;
    (ref($result) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"result\" (value was \"$result\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to bismark:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'bismark');
    }
    return($result);
}




=head2 methylation_extractor

  $result = $obj->methylation_extractor($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Bismark.extractorParams
$result is a kb_Bismark.extractorResult
extractorParams is a reference to a hash where the following keys are defined:
	alignment_ref has a value which is a string
	assembly_or_genome_ref has a value which is a string
	output_workspace has a value which is a string
extractorResult is a reference to a hash where the following keys are defined:
	result_directory has a value which is a string
	bedgraph_ref has a value which is a string
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is a kb_Bismark.extractorParams
$result is a kb_Bismark.extractorResult
extractorParams is a reference to a hash where the following keys are defined:
	alignment_ref has a value which is a string
	assembly_or_genome_ref has a value which is a string
	output_workspace has a value which is a string
extractorResult is a reference to a hash where the following keys are defined:
	result_directory has a value which is a string
	bedgraph_ref has a value which is a string
	report_name has a value which is a string
	report_ref has a value which is a string


=end text



=item Description



=back

=cut

sub methylation_extractor
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to methylation_extractor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'methylation_extractor');
    }

    my $ctx = $kb_Bismark::kb_BismarkServer::CallContext;
    my($result);
    #BEGIN methylation_extractor
    print 'Running methylation_extractor() with params=' . "\n";
    print Dumper($params);
    my $result={};
    #END methylation_extractor
    my @_bad_returns;
    (ref($result) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"result\" (value was \"$result\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to methylation_extractor:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'methylation_extractor');
    }
    return($result);
}




=head2 bismark_app

  $result = $obj->bismark_app($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Bismark.bismarkAppParams
$result is a kb_Bismark.bismarkAppResult
bismarkAppParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
	assembly_or_genome_ref has a value which is a string
	output_workspace has a value which is a string
	lib_type has a value which is a string
	mismatch has a value which is an int
	length has a value which is an int
	qual has a value which is a string
	minins has a value which is an int
	maxins has a value which is an int
bismarkAppResult is a reference to a hash where the following keys are defined:
	alignment_ref has a value which is a string
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is a kb_Bismark.bismarkAppParams
$result is a kb_Bismark.bismarkAppResult
bismarkAppParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
	assembly_or_genome_ref has a value which is a string
	output_workspace has a value which is a string
	lib_type has a value which is a string
	mismatch has a value which is an int
	length has a value which is an int
	qual has a value which is a string
	minins has a value which is an int
	maxins has a value which is an int
bismarkAppResult is a reference to a hash where the following keys are defined:
	alignment_ref has a value which is a string
	report_name has a value which is a string
	report_ref has a value which is a string


=end text



=item Description



=back

=cut

sub bismark_app
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to bismark_app:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'bismark_app');
    }

    my $ctx = $kb_Bismark::kb_BismarkServer::CallContext;
    my($result);
    #BEGIN bismark_app
    print 'Running bismark_app() with params=' . "\n";
    print Dumper($params);
    $result=$self->bismark($params);
    #END bismark_app
    my @_bad_returns;
    (ref($result) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"result\" (value was \"$result\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to bismark_app:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'bismark_app');
    }
    return($result);
}




=head2 run_bismark_cli

  $obj->run_bismark_cli($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Bismark.RunBismarkCLIParams
RunBismarkCLIParams is a reference to a hash where the following keys are defined:
	command_name has a value which is a string
	options has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$params is a kb_Bismark.RunBismarkCLIParams
RunBismarkCLIParams is a reference to a hash where the following keys are defined:
	command_name has a value which is a string
	options has a value which is a reference to a list where each element is a string


=end text



=item Description



=back

=cut

sub run_bismark_cli
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to run_bismark_cli:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'run_bismark_cli');
    }

    my $ctx = $kb_Bismark::kb_BismarkServer::CallContext;
    #BEGIN run_bismark_cli
    print 'Running run_bismark_cli() with params=' . "\n";
    print Dumper($params);
    
    $params->{command} or die 'required parameter field "command" was missing.';
    $params->{options} or die 'required parameter field "options" was missing.';

    my $runner=kb_Bismark::Util::BismarkRunner->new($self->{scratch});
    $runner->run($params->{command}, $params->{options});
    #END run_bismark_cli
    return();
}




=head2 status 

  $return = $obj->status()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module status. This is a structure including Semantic Versioning number, state and git info.

=back

=cut

sub status {
    my($return);
    #BEGIN_STATUS
    $return = {"state" => "OK", "message" => "", "version" => $VERSION,
               "git_url" => $GIT_URL, "git_commit_hash" => $GIT_COMMIT_HASH};
    #END_STATUS
    return($return);
}

=head1 TYPES



=head2 boolean

=over 4



=item Description

A boolean - 0 for false, 1 for true.
@range (0, 1)


=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 preparationParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
assembly_or_genome_ref has a value which is a string
output_dir has a value which is a string
ws_for_cache has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
assembly_or_genome_ref has a value which is a string
output_dir has a value which is a string
ws_for_cache has a value which is a string


=end text

=back



=head2 preparationResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
output_dir has a value which is a string
from_cache has a value which is a kb_Bismark.boolean
pushed_to_cache has a value which is a kb_Bismark.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
output_dir has a value which is a string
from_cache has a value which is a kb_Bismark.boolean
pushed_to_cache has a value which is a kb_Bismark.boolean


=end text

=back



=head2 bismarkParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
input_ref has a value which is a string
assembly_or_genome_ref has a value which is a string
output_workspace has a value which is a string
lib_type has a value which is a string
mismatch has a value which is an int
length has a value which is an int
qual has a value which is a string
minins has a value which is an int
maxins has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
input_ref has a value which is a string
assembly_or_genome_ref has a value which is a string
output_workspace has a value which is a string
lib_type has a value which is a string
mismatch has a value which is an int
length has a value which is an int
qual has a value which is a string
minins has a value which is an int
maxins has a value which is an int


=end text

=back



=head2 bismarkResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
alignment_ref has a value which is a string
report_name has a value which is a string
report_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
alignment_ref has a value which is a string
report_name has a value which is a string
report_ref has a value which is a string


=end text

=back



=head2 bismarkAppParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
input_ref has a value which is a string
assembly_or_genome_ref has a value which is a string
output_workspace has a value which is a string
lib_type has a value which is a string
mismatch has a value which is an int
length has a value which is an int
qual has a value which is a string
minins has a value which is an int
maxins has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
input_ref has a value which is a string
assembly_or_genome_ref has a value which is a string
output_workspace has a value which is a string
lib_type has a value which is a string
mismatch has a value which is an int
length has a value which is an int
qual has a value which is a string
minins has a value which is an int
maxins has a value which is an int


=end text

=back



=head2 bismarkAppResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
alignment_ref has a value which is a string
report_name has a value which is a string
report_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
alignment_ref has a value which is a string
report_name has a value which is a string
report_ref has a value which is a string


=end text

=back



=head2 extractorParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
alignment_ref has a value which is a string
assembly_or_genome_ref has a value which is a string
output_workspace has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
alignment_ref has a value which is a string
assembly_or_genome_ref has a value which is a string
output_workspace has a value which is a string


=end text

=back



=head2 extractorResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
result_directory has a value which is a string
bedgraph_ref has a value which is a string
report_name has a value which is a string
report_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
result_directory has a value which is a string
bedgraph_ref has a value which is a string
report_name has a value which is a string
report_ref has a value which is a string


=end text

=back



=head2 RunBismarkCLIParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
command_name has a value which is a string
options has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
command_name has a value which is a string
options has a value which is a reference to a list where each element is a string


=end text

=back



=cut

1;
