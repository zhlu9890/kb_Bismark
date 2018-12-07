package ReadsAlignmentUtils::ReadsAlignmentUtilsClient;

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

ReadsAlignmentUtils::ReadsAlignmentUtilsClient

=head1 DESCRIPTION


A KBase module: ReadsAlignmentUtils

This module is intended for use by Aligners and Assemblers to upload and download alignment files.
The alignment may be uploaded as a sam or bam file. If a sam file is given, it is converted to
the sorted bam format and saved. Upon downloading, optional parameters may be provided to get files
in sam and bai formats from the downloaded bam file. This utility also generates stats from the
stored alignment.


=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => ReadsAlignmentUtils::ReadsAlignmentUtilsClient::RpcClient->new,
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
        method => "ReadsAlignmentUtils._check_job",
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




=head2 validate_alignment

  $return = $obj->validate_alignment($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a ReadsAlignmentUtils.ValidateAlignmentParams
$return is a ReadsAlignmentUtils.ValidateAlignmentOutput
ValidateAlignmentParams is a reference to a hash where the following keys are defined:
	file_path has a value which is a string
	ignore has a value which is a reference to a list where each element is a string
ValidateAlignmentOutput is a reference to a hash where the following keys are defined:
	validated has a value which is a ReadsAlignmentUtils.boolean
boolean is an int

</pre>

=end html

=begin text

$params is a ReadsAlignmentUtils.ValidateAlignmentParams
$return is a ReadsAlignmentUtils.ValidateAlignmentOutput
ValidateAlignmentParams is a reference to a hash where the following keys are defined:
	file_path has a value which is a string
	ignore has a value which is a reference to a list where each element is a string
ValidateAlignmentOutput is a reference to a hash where the following keys are defined:
	validated has a value which is a ReadsAlignmentUtils.boolean
boolean is an int


=end text

=item Description



=back

=cut

sub validate_alignment
{
    my($self, @args) = @_;
    my $job_id = $self->_validate_alignment_submit(@args);
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

sub _validate_alignment_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _validate_alignment_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _validate_alignment_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_validate_alignment_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "ReadsAlignmentUtils._validate_alignment_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_validate_alignment_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _validate_alignment_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_validate_alignment_submit');
    }
}

 


=head2 upload_alignment

  $return = $obj->upload_alignment($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a ReadsAlignmentUtils.UploadAlignmentParams
$return is a ReadsAlignmentUtils.UploadAlignmentOutput
UploadAlignmentParams is a reference to a hash where the following keys are defined:
	destination_ref has a value which is a string
	file_path has a value which is a string
	read_library_ref has a value which is a string
	condition has a value which is a string
	assembly_or_genome_ref has a value which is a string
	aligned_using has a value which is a string
	aligner_version has a value which is a string
	aligner_opts has a value which is a reference to a hash where the key is a string and the value is a string
	replicate_id has a value which is a string
	platform has a value which is a string
	bowtie2_index has a value which is a ReadsAlignmentUtils.ws_bowtieIndex_id
	sampleset_ref has a value which is a ReadsAlignmentUtils.ws_Sampleset_ref
	mapped_sample_id has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a string
	validate has a value which is a ReadsAlignmentUtils.boolean
	ignore has a value which is a reference to a list where each element is a string
ws_bowtieIndex_id is a string
ws_Sampleset_ref is a string
boolean is an int
UploadAlignmentOutput is a reference to a hash where the following keys are defined:
	obj_ref has a value which is a string

</pre>

=end html

=begin text

$params is a ReadsAlignmentUtils.UploadAlignmentParams
$return is a ReadsAlignmentUtils.UploadAlignmentOutput
UploadAlignmentParams is a reference to a hash where the following keys are defined:
	destination_ref has a value which is a string
	file_path has a value which is a string
	read_library_ref has a value which is a string
	condition has a value which is a string
	assembly_or_genome_ref has a value which is a string
	aligned_using has a value which is a string
	aligner_version has a value which is a string
	aligner_opts has a value which is a reference to a hash where the key is a string and the value is a string
	replicate_id has a value which is a string
	platform has a value which is a string
	bowtie2_index has a value which is a ReadsAlignmentUtils.ws_bowtieIndex_id
	sampleset_ref has a value which is a ReadsAlignmentUtils.ws_Sampleset_ref
	mapped_sample_id has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a string
	validate has a value which is a ReadsAlignmentUtils.boolean
	ignore has a value which is a reference to a list where each element is a string
ws_bowtieIndex_id is a string
ws_Sampleset_ref is a string
boolean is an int
UploadAlignmentOutput is a reference to a hash where the following keys are defined:
	obj_ref has a value which is a string


=end text

=item Description

Validates and uploads the reads alignment  

        How we compute BAM stats:

        For each segment (line) in SAM/BAM file:
            we take the first element as `reads_id`
                    the second element as `flag`

            if the last bit (0x1) of flag is `1`:
                we treat this segment as paired end reads
            otherwise:
                we treat this segment as single end reads

            For single end reads:
                if the 3rd last bit (0x8) of flag is `1`:
                    we increment unmapped_reads_count
                else:
                    we treat this `reads_id` as mapped

                for all mapped `reads_ids`"
                    if it appears only once:
                        we treat this `reads_id` as `singletons`
                    else:
                        we treat this `reads_id` as `multiple_alignments`

                lastly, total_reads = unmapped_reads_count + identical mapped `reads_id`

            For paired end reads:
                if the 7th last bit (0x40) of flag is `1`:
                    if the 3rd last bit (0x8) of flag is `1`:
                        we increment unmapped_left_reads_count
                    else:
                        we treat this `reads_id` as mapped

                if the 8th last bit ( 0x80) of flag is `1`:
                    if the 3rd last bit (0x8) of flag is `1`:
                        we increment unmapped_right_reads_count
                    else:
                        we treat this `reads_id` as mapped

                for all mapped `reads_ids`"
                    if it appears only once:
                        we treat this `reads_id` as `singletons`
                    else:
                        we treat this `reads_id` as `multiple_alignments`

                lastly, total_reads = unmapped_left_reads_count + unmapped_right_reads_count + identical mapped `reads_id`

=back

=cut

sub upload_alignment
{
    my($self, @args) = @_;
    my $job_id = $self->_upload_alignment_submit(@args);
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

sub _upload_alignment_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _upload_alignment_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _upload_alignment_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_upload_alignment_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "ReadsAlignmentUtils._upload_alignment_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_upload_alignment_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _upload_alignment_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_upload_alignment_submit');
    }
}

 


=head2 download_alignment

  $return = $obj->download_alignment($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a ReadsAlignmentUtils.DownloadAlignmentParams
$return is a ReadsAlignmentUtils.DownloadAlignmentOutput
DownloadAlignmentParams is a reference to a hash where the following keys are defined:
	source_ref has a value which is a string
	downloadSAM has a value which is a ReadsAlignmentUtils.boolean
	downloadBAI has a value which is a ReadsAlignmentUtils.boolean
	validate has a value which is a ReadsAlignmentUtils.boolean
	ignore has a value which is a reference to a list where each element is a string
boolean is an int
DownloadAlignmentOutput is a reference to a hash where the following keys are defined:
	destination_dir has a value which is a string
	stats has a value which is a ReadsAlignmentUtils.AlignmentStats
AlignmentStats is a reference to a hash where the following keys are defined:
	properly_paired has a value which is an int
	multiple_alignments has a value which is an int
	singletons has a value which is an int
	alignment_rate has a value which is a float
	unmapped_reads has a value which is an int
	mapped_reads has a value which is an int
	total_reads has a value which is an int

</pre>

=end html

=begin text

$params is a ReadsAlignmentUtils.DownloadAlignmentParams
$return is a ReadsAlignmentUtils.DownloadAlignmentOutput
DownloadAlignmentParams is a reference to a hash where the following keys are defined:
	source_ref has a value which is a string
	downloadSAM has a value which is a ReadsAlignmentUtils.boolean
	downloadBAI has a value which is a ReadsAlignmentUtils.boolean
	validate has a value which is a ReadsAlignmentUtils.boolean
	ignore has a value which is a reference to a list where each element is a string
boolean is an int
DownloadAlignmentOutput is a reference to a hash where the following keys are defined:
	destination_dir has a value which is a string
	stats has a value which is a ReadsAlignmentUtils.AlignmentStats
AlignmentStats is a reference to a hash where the following keys are defined:
	properly_paired has a value which is an int
	multiple_alignments has a value which is an int
	singletons has a value which is an int
	alignment_rate has a value which is a float
	unmapped_reads has a value which is an int
	mapped_reads has a value which is an int
	total_reads has a value which is an int


=end text

=item Description

Downloads alignment files in .bam, .sam and .bai formats. Also downloads alignment stats *

=back

=cut

sub download_alignment
{
    my($self, @args) = @_;
    my $job_id = $self->_download_alignment_submit(@args);
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

sub _download_alignment_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _download_alignment_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _download_alignment_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_download_alignment_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "ReadsAlignmentUtils._download_alignment_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_download_alignment_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _download_alignment_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_download_alignment_submit');
    }
}

 


=head2 export_alignment

  $output = $obj->export_alignment($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a ReadsAlignmentUtils.ExportParams
$output is a ReadsAlignmentUtils.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	source_ref has a value which is a string
	exportSAM has a value which is a ReadsAlignmentUtils.boolean
	exportBAI has a value which is a ReadsAlignmentUtils.boolean
	validate has a value which is a ReadsAlignmentUtils.boolean
	ignore has a value which is a reference to a list where each element is a string
boolean is an int
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a ReadsAlignmentUtils.ExportParams
$output is a ReadsAlignmentUtils.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	source_ref has a value which is a string
	exportSAM has a value which is a ReadsAlignmentUtils.boolean
	exportBAI has a value which is a ReadsAlignmentUtils.boolean
	validate has a value which is a ReadsAlignmentUtils.boolean
	ignore has a value which is a reference to a list where each element is a string
boolean is an int
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text

=item Description

Wrapper function for use by in-narrative downloaders to download alignments from shock *

=back

=cut

sub export_alignment
{
    my($self, @args) = @_;
    my $job_id = $self->_export_alignment_submit(@args);
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

sub _export_alignment_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _export_alignment_submit (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _export_alignment_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_export_alignment_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "ReadsAlignmentUtils._export_alignment_submit",
        params => \@args, context => $context});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_export_alignment_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _export_alignment_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_export_alignment_submit');
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
        method => "ReadsAlignmentUtils._status_submit",
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
        method => "ReadsAlignmentUtils.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'export_alignment',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method export_alignment",
            status_line => $self->{client}->status_line,
            method_name => 'export_alignment',
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
        warn "New client version available for ReadsAlignmentUtils::ReadsAlignmentUtilsClient\n";
    }
    if ($sMajor == 0) {
        warn "ReadsAlignmentUtils::ReadsAlignmentUtilsClient version is $svr_version. API subject to change.\n";
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



=head2 ws_bowtieIndex_id

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 ws_Sampleset_ref

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 ValidateAlignmentParams

=over 4



=item Description

* Input parameters for validating a reads alignment. For validation errors to ignore,
see http://broadinstitute.github.io/picard/command-line-overview.html#ValidateSamFile


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
file_path has a value which is a string
ignore has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
file_path has a value which is a string
ignore has a value which is a reference to a list where each element is a string


=end text

=back



=head2 ValidateAlignmentOutput

=over 4



=item Description

* Results from validate alignment *


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
validated has a value which is a ReadsAlignmentUtils.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
validated has a value which is a ReadsAlignmentUtils.boolean


=end text

=back



=head2 UploadAlignmentParams

=over 4



=item Description

*
Required input parameters for uploading a reads alignment

  string destination_ref -  object reference of alignment destination. The
                            object ref is 'ws_name_or_id/obj_name_or_id'
                            where ws_name_or_id is the workspace name or id
                            and obj_name_or_id is the object name or id

  file_path              -  File with the path of the sam or bam file to be uploaded.
                            If a sam file is provided, it will be converted to the sorted
                            bam format before being saved

  read_library_ref       -  workspace object ref of the read sample used to make
                            the alignment file
  condition              -
  assembly_or_genome_ref -  workspace object ref of genome assembly or genome object that was
                            used to build the alignment
    *


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
destination_ref has a value which is a string
file_path has a value which is a string
read_library_ref has a value which is a string
condition has a value which is a string
assembly_or_genome_ref has a value which is a string
aligned_using has a value which is a string
aligner_version has a value which is a string
aligner_opts has a value which is a reference to a hash where the key is a string and the value is a string
replicate_id has a value which is a string
platform has a value which is a string
bowtie2_index has a value which is a ReadsAlignmentUtils.ws_bowtieIndex_id
sampleset_ref has a value which is a ReadsAlignmentUtils.ws_Sampleset_ref
mapped_sample_id has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a string
validate has a value which is a ReadsAlignmentUtils.boolean
ignore has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
destination_ref has a value which is a string
file_path has a value which is a string
read_library_ref has a value which is a string
condition has a value which is a string
assembly_or_genome_ref has a value which is a string
aligned_using has a value which is a string
aligner_version has a value which is a string
aligner_opts has a value which is a reference to a hash where the key is a string and the value is a string
replicate_id has a value which is a string
platform has a value which is a string
bowtie2_index has a value which is a ReadsAlignmentUtils.ws_bowtieIndex_id
sampleset_ref has a value which is a ReadsAlignmentUtils.ws_Sampleset_ref
mapped_sample_id has a value which is a reference to a hash where the key is a string and the value is a reference to a hash where the key is a string and the value is a string
validate has a value which is a ReadsAlignmentUtils.boolean
ignore has a value which is a reference to a list where each element is a string


=end text

=back



=head2 UploadAlignmentOutput

=over 4



=item Description

*  Output from uploading a reads alignment  *


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
obj_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
obj_ref has a value which is a string


=end text

=back



=head2 DownloadAlignmentParams

=over 4



=item Description

*
Required input parameters for downloading a reads alignment

string source_ref -  object reference of alignment source. The
                     object ref is 'ws_name_or_id/obj_name_or_id'
                     where ws_name_or_id is the workspace name or id
                     and obj_name_or_id is the object name or id
    *


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
source_ref has a value which is a string
downloadSAM has a value which is a ReadsAlignmentUtils.boolean
downloadBAI has a value which is a ReadsAlignmentUtils.boolean
validate has a value which is a ReadsAlignmentUtils.boolean
ignore has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
source_ref has a value which is a string
downloadSAM has a value which is a ReadsAlignmentUtils.boolean
downloadBAI has a value which is a ReadsAlignmentUtils.boolean
validate has a value which is a ReadsAlignmentUtils.boolean
ignore has a value which is a reference to a list where each element is a string


=end text

=back



=head2 AlignmentStats

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
properly_paired has a value which is an int
multiple_alignments has a value which is an int
singletons has a value which is an int
alignment_rate has a value which is a float
unmapped_reads has a value which is an int
mapped_reads has a value which is an int
total_reads has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
properly_paired has a value which is an int
multiple_alignments has a value which is an int
singletons has a value which is an int
alignment_rate has a value which is a float
unmapped_reads has a value which is an int
mapped_reads has a value which is an int
total_reads has a value which is an int


=end text

=back



=head2 DownloadAlignmentOutput

=over 4



=item Description

*  The output of the download method.  *


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
destination_dir has a value which is a string
stats has a value which is a ReadsAlignmentUtils.AlignmentStats

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
destination_dir has a value which is a string
stats has a value which is a ReadsAlignmentUtils.AlignmentStats


=end text

=back



=head2 ExportParams

=over 4



=item Description

*
Required input parameters for exporting a reads alignment

string source_ref -  object reference of alignment source. The
                     object ref is 'ws_name_or_id/obj_name_or_id'
                     where ws_name_or_id is the workspace name or id
                     and obj_name_or_id is the object name or id
    *


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
source_ref has a value which is a string
exportSAM has a value which is a ReadsAlignmentUtils.boolean
exportBAI has a value which is a ReadsAlignmentUtils.boolean
validate has a value which is a ReadsAlignmentUtils.boolean
ignore has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
source_ref has a value which is a string
exportSAM has a value which is a ReadsAlignmentUtils.boolean
exportBAI has a value which is a ReadsAlignmentUtils.boolean
validate has a value which is a ReadsAlignmentUtils.boolean
ignore has a value which is a reference to a list where each element is a string


=end text

=back



=head2 ExportOutput

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
shock_id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
shock_id has a value which is a string


=end text

=back



=cut

package ReadsAlignmentUtils::ReadsAlignmentUtilsClient::RpcClient;
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
