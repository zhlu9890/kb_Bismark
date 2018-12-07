package KBParallel::KBParallelClient;

use JSON::RPC::Client;
use POSIX;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;
use Time::HiRes;
my $get_time = sub { time, 0 };
eval {
    require Time::HiRes;
    $get_time = sub { Time::HiRes::gettimeofday() };
};

use Bio::KBase::AuthToken;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

KBParallel::KBParallelClient

=head1 DESCRIPTION


Module for distributing a set of jobs in batch to run either locally or on njsw


=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => KBParallel::KBParallelClient::RpcClient->new,
	url => $url,
	headers => [],
    };
    my %arg_hash = @args;
    $self->{async_job_check_time} = 0.1;
    if (exists $arg_hash{"async_job_check_time_ms"}) {
        $self->{async_job_check_time} = $arg_hash{"async_job_check_time_ms"} / 1000.0;
    }
    $self->{async_job_check_time_scale_percent} = 150;
    if (exists $arg_hash{"async_job_check_time_scale_percent"}) {
        $self->{async_job_check_time_scale_percent} = $arg_hash{"async_job_check_time_scale_percent"};
    }
    $self->{async_job_check_max_time} = 300;  # 5 minutes
    if (exists $arg_hash{"async_job_check_max_time_ms"}) {
        $self->{async_job_check_max_time} = $arg_hash{"async_job_check_max_time_ms"} / 1000.0;
    }
    my $service_version = 'release';
    if (exists $arg_hash{"service_version"}) {
        $service_version = $arg_hash{"service_version"};
    }
    $self->{service_version} = $service_version;

    chomp($self->{hostname} = `hostname`);
    $self->{hostname} ||= 'unknown-host';

    #
    # Set up for propagating KBRPC_TAG and KBRPC_METADATA environment variables through
    # to invoked services. If these values are not set, we create a new tag
    # and a metadata field with basic information about the invoking script.
    #
    if ($ENV{KBRPC_TAG})
    {
	$self->{kbrpc_tag} = $ENV{KBRPC_TAG};
    }
    else
    {
	my ($t, $us) = &$get_time();
	$us = sprintf("%06d", $us);
	my $ts = strftime("%Y-%m-%dT%H:%M:%S.${us}Z", gmtime $t);
	$self->{kbrpc_tag} = "C:$0:$self->{hostname}:$$:$ts";
    }
    push(@{$self->{headers}}, 'Kbrpc-Tag', $self->{kbrpc_tag});

    if ($ENV{KBRPC_METADATA})
    {
	$self->{kbrpc_metadata} = $ENV{KBRPC_METADATA};
	push(@{$self->{headers}}, 'Kbrpc-Metadata', $self->{kbrpc_metadata});
    }

    if ($ENV{KBRPC_ERROR_DEST})
    {
	$self->{kbrpc_error_dest} = $ENV{KBRPC_ERROR_DEST};
	push(@{$self->{headers}}, 'Kbrpc-Errordest', $self->{kbrpc_error_dest});
    }

    #
    # This module requires authentication.
    #
    # We create an auth token, passing through the arguments that we were (hopefully) given.

    {
	my %arg_hash2 = @args;
	if (exists $arg_hash2{"token"}) {
	    $self->{token} = $arg_hash2{"token"};
	} elsif (exists $arg_hash2{"user_id"}) {
	    my $token = Bio::KBase::AuthToken->new(@args);
	    if (!$token->error_message) {
	        $self->{token} = $token->token;
	    }
	}
	
	if (exists $self->{token})
	{
	    $self->{client}->{token} = $self->{token};
	}
    }

    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}

sub _check_job {
    my($self, @args) = @_;
# Authentication: ${method.authentication}
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _check_job (received $n, expecting 1)");
    }
    {
        my($job_id) = @args;
        my @_bad_arguments;
        (!ref($job_id)) or push(@_bad_arguments, "Invalid type for argument 0 \"job_id\" (it should be a string)");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _check_job:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_check_job');
        }
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "KBParallel._check_job",
        params => \@args});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_check_job',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
                          );
        } else {
            return $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _check_job",
                        status_line => $self->{client}->status_line,
                        method_name => '_check_job');
    }
}




=head2 run_batch

  $results = $obj->run_batch($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a KBParallel.RunBatchParams
$results is a KBParallel.BatchResults
RunBatchParams is a reference to a hash where the following keys are defined:
	tasks has a value which is a reference to a list where each element is a KBParallel.Task
	runner has a value which is a string
	concurrent_local_tasks has a value which is an int
	concurrent_njsw_tasks has a value which is an int
	max_retries has a value which is an int
Task is a reference to a hash where the following keys are defined:
	function has a value which is a KBParallel.Function
	params has a value which is an UnspecifiedObject, which can hold any non-null object
Function is a reference to a hash where the following keys are defined:
	module_name has a value which is a string
	function_name has a value which is a string
	version has a value which is a string
BatchResults is a reference to a hash where the following keys are defined:
	results has a value which is a reference to a list where each element is a KBParallel.TaskResult
TaskResult is a reference to a hash where the following keys are defined:
	is_error has a value which is a KBParallel.boolean
	result_package has a value which is a KBParallel.ResultPackage
boolean is an int
ResultPackage is a reference to a hash where the following keys are defined:
	function has a value which is a KBParallel.Function
	result has a value which is an UnspecifiedObject, which can hold any non-null object
	error has a value which is an UnspecifiedObject, which can hold any non-null object
	run_context has a value which is a KBParallel.RunContext
RunContext is a reference to a hash where the following keys are defined:
	location has a value which is a string
	job_id has a value which is a string

</pre>

=end html

=begin text

$params is a KBParallel.RunBatchParams
$results is a KBParallel.BatchResults
RunBatchParams is a reference to a hash where the following keys are defined:
	tasks has a value which is a reference to a list where each element is a KBParallel.Task
	runner has a value which is a string
	concurrent_local_tasks has a value which is an int
	concurrent_njsw_tasks has a value which is an int
	max_retries has a value which is an int
Task is a reference to a hash where the following keys are defined:
	function has a value which is a KBParallel.Function
	params has a value which is an UnspecifiedObject, which can hold any non-null object
Function is a reference to a hash where the following keys are defined:
	module_name has a value which is a string
	function_name has a value which is a string
	version has a value which is a string
BatchResults is a reference to a hash where the following keys are defined:
	results has a value which is a reference to a list where each element is a KBParallel.TaskResult
TaskResult is a reference to a hash where the following keys are defined:
	is_error has a value which is a KBParallel.boolean
	result_package has a value which is a KBParallel.ResultPackage
boolean is an int
ResultPackage is a reference to a hash where the following keys are defined:
	function has a value which is a KBParallel.Function
	result has a value which is an UnspecifiedObject, which can hold any non-null object
	error has a value which is an UnspecifiedObject, which can hold any non-null object
	run_context has a value which is a KBParallel.RunContext
RunContext is a reference to a hash where the following keys are defined:
	location has a value which is a string
	job_id has a value which is a string


=end text

=item Description



=back

=cut

sub run_batch
{
    my($self, @args) = @_;
    my $job_id = $self->_run_batch_submit(@args);
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _run_batch_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _run_batch_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _run_batch_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_run_batch_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "KBParallel._run_batch_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_run_batch_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _run_batch_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_run_batch_submit');
    }
}

 
 
sub status
{
    my($self, @args) = @_;
    my $job_id = undef;
    if ((my $n = @args) != 0) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function status (received $n, expecting 0)");
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "KBParallel._status_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_status_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            $job_id = $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _status_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_status_submit');
    }
    my $async_job_check_time = $self->{async_job_check_time};
    while (1) {
        Time::HiRes::sleep($async_job_check_time);
        $async_job_check_time *= $self->{async_job_check_time_scale_percent} / 100.0;
        if ($async_job_check_time > $self->{async_job_check_max_time}) {
            $async_job_check_time = $self->{async_job_check_max_time};
        }
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}
   

sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "KBParallel.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'run_batch',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method run_batch",
            status_line => $self->{client}->status_line,
            method_name => 'run_batch',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for KBParallel::KBParallelClient\n";
    }
    if ($sMajor == 0) {
        warn "KBParallel::KBParallelClient version is $svr_version. API subject to change.\n";
    }
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



=head2 Function

=over 4



=item Description

Specifies a specific KBase module function to run


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
module_name has a value which is a string
function_name has a value which is a string
version has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
module_name has a value which is a string
function_name has a value which is a string
version has a value which is a string


=end text

=back



=head2 Task

=over 4



=item Description

Specifies a task to run.  Parameters is an arbitrary data object
passed to the function.  If it is a list, the params will be interpreted
as


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
function has a value which is a KBParallel.Function
params has a value which is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
function has a value which is a KBParallel.Function
params has a value which is an UnspecifiedObject, which can hold any non-null object


=end text

=back



=head2 RunContext

=over 4



=item Description

location = local | njsw
job_id = '' | [njsw_job_id]

May want to add: AWE node ID, client group, total run time, etc


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
location has a value which is a string
job_id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
location has a value which is a string
job_id has a value which is a string


=end text

=back



=head2 ResultPackage

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
function has a value which is a KBParallel.Function
result has a value which is an UnspecifiedObject, which can hold any non-null object
error has a value which is an UnspecifiedObject, which can hold any non-null object
run_context has a value which is a KBParallel.RunContext

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
function has a value which is a KBParallel.Function
result has a value which is an UnspecifiedObject, which can hold any non-null object
error has a value which is an UnspecifiedObject, which can hold any non-null object
run_context has a value which is a KBParallel.RunContext


=end text

=back



=head2 TaskResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
is_error has a value which is a KBParallel.boolean
result_package has a value which is a KBParallel.ResultPackage

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
is_error has a value which is a KBParallel.boolean
result_package has a value which is a KBParallel.ResultPackage


=end text

=back



=head2 BatchResults

=over 4



=item Description

The list of results will be in the same order as the input list of tasks.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
results has a value which is a reference to a list where each element is a KBParallel.TaskResult

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
results has a value which is a reference to a list where each element is a KBParallel.TaskResult


=end text

=back



=head2 RunBatchParams

=over 4



=item Description

runner = serial_local | parallel_local | parallel
    serial_local will run tasks on the node in serial, ignoring the concurrent
        task limits
    parallel_local will run multiple tasks on the node in parallel, and will
        ignore the njsw_task parameter. Unless you know where your job will
        run, you probably don't want to set this higher than 2
    parallel will look at both the local task and njsw task limits and operate
        appropriately. Therefore, you could always just select this option and
        tweak the task limits to get either serial_local or parallel_local
        behavior.

TODO:
wsid - if defined, the workspace id or name (service will handle either string or
       int) on which to attach the job. Anyone with permissions to that WS will
       be able to view job status for this run.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
tasks has a value which is a reference to a list where each element is a KBParallel.Task
runner has a value which is a string
concurrent_local_tasks has a value which is an int
concurrent_njsw_tasks has a value which is an int
max_retries has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
tasks has a value which is a reference to a list where each element is a KBParallel.Task
runner has a value which is a string
concurrent_local_tasks has a value which is an int
concurrent_njsw_tasks has a value which is an int
max_retries has a value which is an int


=end text

=back



=cut

package KBParallel::KBParallelClient::RpcClient;
use base 'JSON::RPC::Client';
use POSIX;
use strict;

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $headers, $obj) = @_;
    my $result;


    {
	if ($uri =~ /\?/) {
	    $result = $self->_get($uri);
	}
	else {
	    Carp::croak "not hashref." unless (ref $obj eq 'HASH');
	    $result = $self->_post($uri, $headers, $obj);
	}

    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}


sub _post {
    my ($self, $uri, $headers, $obj) = @_;
    my $json = $self->json;

    $obj->{version} ||= $self->{version} || '1.1';

    if ($obj->{version} eq '1.0') {
        delete $obj->{version};
        if (exists $obj->{id}) {
            $self->id($obj->{id}) if ($obj->{id}); # if undef, it is notification.
        }
        else {
            $obj->{id} = $self->id || ($self->id('JSON::RPC::Client'));
        }
    }
    else {
        # $obj->{id} = $self->id if (defined $self->id);
	# Assign a random number to the id if one hasn't been set
	$obj->{id} = (defined $self->id) ? $self->id : substr(rand(),2);
    }

    my $content = $json->encode($obj);

    $self->ua->post(
        $uri,
        Content_Type   => $self->{content_type},
        Content        => $content,
        Accept         => 'application/json',
	@$headers,
	($self->{token} ? (Authorization => $self->{token}) : ()),
    );
}



1;
