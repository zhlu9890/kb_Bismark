use strict;
use Data::Dumper;
use Test::More;
use Test::Exception;
use Config::Simple;
use Time::HiRes qw(time);
use Bio::KBase::AuthToken;
use Workspace::WorkspaceClient;
use AssemblyUtil::AssemblyUtilClient;
use ReadsUtils::ReadsUtilsClient;
use kb_Bismark::kb_BismarkImpl;

use File::Spec;
use File::Copy;
use File::Path qw(make_path);
$Data::Dumper::Terse = 1;

#local $| = 1;
my $token = $ENV{'KB_AUTH_TOKEN'};
my $config_file = $ENV{'KB_DEPLOYMENT_CONFIG'};
my $config = new Config::Simple($config_file)->get_block('kb_Bismark');
my $ws_url = $config->{"workspace-url"};
my $ws_name = undef;
my $ws_client = new Workspace::WorkspaceClient($ws_url,token => $token);
my $scratch = $config->{scratch};
my $callback_url = $ENV{'SDK_CALLBACK_URL'};
my $auth_token = Bio::KBase::AuthToken->new(token => $token, ignore_authrc => 1, auth_svc=>$config->{'auth-service-url'});
my $ctx = LocalCallContext->new($token, $auth_token->user_id);
$kb_Bismark::kb_BismarkServer::CallContext = $ctx;
my $impl = new kb_Bismark::kb_BismarkImpl();

sub get_ws_name {
    if (!defined($ws_name)) {
        my $suffix = int(time * 1000);
        $ws_name = 'test_kb_Bismark_' . $suffix;
        $ws_client->create_workspace({workspace => $ws_name});
    }
    return $ws_name;
}

sub loadAssembly {
  my $fa_path=File::Spec->catfile($scratch, 'chr8.fa');
  copy(File::Spec->catfile('data', 'chr8.fa'), $fa_path);
  my $au=AssemblyUtil::AssemblyUtilClient->new($callback_url);
  my $assembly_ref = $au->save_assembly_from_fasta({
      file => {path => $fa_path},
      workspace_name => get_ws_name(),
      assembly_name => 'test_assembly'
    }
  );
  return $assembly_ref;
}

sub loadSingleEndReads {
  my $fq_path=File::Spec->catfile($scratch, 'test_reads_bs.fq');
  copy(File::Spec->catfile('data', 'test_reads_bs.fq'), $fq_path);
  my $ru=ReadsUtils::ReadsUtilsClient->new($callback_url);
  my $se_reads_ref = $ru->upload_reads({
      fwd_file => $fq_path,
      wsname => get_ws_name(),
      name => 'test_readsSE',
      sequencing_tech => 'artificial reads'
    }
  )->{obj_ref};
  print 'Loaded SingleEndReads: ' . $se_reads_ref;
  return $se_reads_ref;
}

eval {
    # Prepare test data using the appropriate uploader for that data (see the KBase function
    # catalog for help, https://narrative.kbase.us/#catalog/functions)
    
    # Run your method by
    # my $ret = $impl->your_method(parameters...);
    #
    # Check returned data with
    # ok(ret->{...} eq <expected>, "tested item") or other Test::More methods
  isa_ok($impl, 'kb_Bismark::kb_BismarkImpl');
  diag explain $impl;
  can_ok($impl, qw/genome_preparation bismark methylation_extractor bismark_app run_bismark_cli/);
  my ($assembly_ref, $se_lib_ref, $params, $res);

  lives_ok {
    $assembly_ref = loadAssembly();
    $res=$impl->genome_preparation({ref => $assembly_ref});
  }, 'genome_preparation'; 
  diag explain $res;
  cmp_ok($res->{from_cache}, '==', 0);
  cmp_ok($res->{pushed_to_cache}, '==', 0);
  cmp_ok($res->{index_files_basename}, 'eq', 'test_assembly');

  lives_ok {
    $assembly_ref = loadAssembly();
    $res=$impl->genome_preparation({ref => $assembly_ref, ws_for_cache => get_ws_name()});
  }, 'genome_preparation with ws_for_cache';
  diag explain $res;
  cmp_ok($res->{from_cache}, '==', 0);
  cmp_ok($res->{pushed_to_cache}, '==', 1);
  cmp_ok($res->{index_files_basename}, 'eq', 'test_assembly');

  lives_ok {
    $assembly_ref = loadAssembly();
    $res=$impl->genome_preparation({ref => $assembly_ref});
  }, 'genome_preparation';
  diag explain $res;
  cmp_ok($res->{from_cache}, '==', 1);
  cmp_ok($res->{pushed_to_cache}, '==', 0);
  cmp_ok($res->{index_files_basename}, 'eq', 'test_assembly');

  $params={
    input_ref => $se_lib_ref,
    assembly_or_genome_ref => $assembly_ref,
    output_obj_name_suffix => 'readsAlignment1',
    output_workspace => get_ws_name(),
  };
  lives_ok {
    $assembly_ref = loadAssembly();
    $se_lib_ref = loadSingleEndReads();
    $res = $impl->bismark($params);
  }, 'bismark';
  diag explain $res;
  
  done_testing();
};
my $err = undef;
if ($@) {
    $err = $@;
}
eval {
    if (defined($ws_name)) {
        $ws_client->delete_workspace({workspace => $ws_name});
        print("Test workspace was deleted\n");
    }
};
if (defined($err)) {
    use Scalar::Util 'blessed';
    if(blessed $err && $err->isa("Bio::KBase::Exceptions::KBaseException")) {
        die "Error while running tests. Remote error:\n" . $err->{data} .
            "Client-side error:\n" . $err;
    } else {
        die $err;
    }
}

{
    package LocalCallContext;
    use strict;
    sub new {
        my($class,$token,$user) = @_;
        my $self = {
            token => $token,
            user_id => $user
        };
        return bless $self, $class;
    }
    sub user_id {
        my($self) = @_;
        return $self->{user_id};
    }
    sub token {
        my($self) = @_;
        return $self->{token};
    }
    sub provenance {
        my($self) = @_;
        return [{'service' => 'kb_Bismark', 'method' => 'please_never_use_it_in_production', 'method_params' => []}];
    }
    sub authenticated {
        return 1;
    }
    sub log_debug {
        my($self,$msg) = @_;
        print STDERR $msg."\n";
    }
    sub log_info {
        my($self,$msg) = @_;
        print STDERR $msg."\n";
    }
}
