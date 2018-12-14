package kb_Bismark::kb_BismarkClient;

use JSON::RPC::Client;
use POSIX;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;
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

kb_Bismark::kb_BismarkClient

=head1 DESCRIPTION


A KBase module: kb_Bismark


=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => kb_Bismark::kb_BismarkClient::RpcClient->new,
	url => $url,
	headers => [],
    };

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
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function genome_preparation (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to genome_preparation:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'genome_preparation');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Bismark.genome_preparation",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'genome_preparation',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method genome_preparation",
					    status_line => $self->{client}->status_line,
					    method_name => 'genome_preparation',
				       );
    }
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
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function bismark (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to bismark:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'bismark');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Bismark.bismark",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'bismark',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method bismark",
					    status_line => $self->{client}->status_line,
					    method_name => 'bismark',
				       );
    }
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
extractorResult is a reference to a hash where the following keys are defined:
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is a kb_Bismark.extractorParams
$result is a kb_Bismark.extractorResult
extractorParams is a reference to a hash where the following keys are defined:
	alignment_ref has a value which is a string
extractorResult is a reference to a hash where the following keys are defined:
	report_ref has a value which is a string


=end text

=item Description



=back

=cut

 sub methylation_extractor
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function methylation_extractor (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to methylation_extractor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'methylation_extractor');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Bismark.methylation_extractor",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'methylation_extractor',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method methylation_extractor",
					    status_line => $self->{client}->status_line,
					    method_name => 'methylation_extractor',
				       );
    }
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
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function bismark_app (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to bismark_app:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'bismark_app');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Bismark.bismark_app",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'bismark_app',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method bismark_app",
					    status_line => $self->{client}->status_line,
					    method_name => 'bismark_app',
				       );
    }
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
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function run_bismark_cli (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to run_bismark_cli:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'run_bismark_cli');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Bismark.run_bismark_cli",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'run_bismark_cli',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method run_bismark_cli",
					    status_line => $self->{client}->status_line,
					    method_name => 'run_bismark_cli',
				       );
    }
}
 
  
sub status
{
    my($self, @args) = @_;
    if ((my $n = @args) != 0) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function status (received $n, expecting 0)");
    }
    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
        method => "kb_Bismark.status",
        params => \@args,
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => 'status',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
                          );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method status",
                        status_line => $self->{client}->status_line,
                        method_name => 'status',
                       );
    }
}
   

sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "kb_Bismark.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'run_bismark_cli',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method run_bismark_cli",
            status_line => $self->{client}->status_line,
            method_name => 'run_bismark_cli',
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
        warn "New client version available for kb_Bismark::kb_BismarkClient\n";
    }
    if ($sMajor == 0) {
        warn "kb_Bismark::kb_BismarkClient version is $svr_version. API subject to change.\n";
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

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
alignment_ref has a value which is a string


=end text

=back



=head2 extractorResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
report_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
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

package kb_Bismark::kb_BismarkClient::RpcClient;
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
