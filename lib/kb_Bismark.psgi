use kb_Bismark::kb_BismarkImpl;

use kb_Bismark::kb_BismarkServer;
use Plack::Middleware::CrossOrigin;



my @dispatch;

{
    my $obj = kb_Bismark::kb_BismarkImpl->new;
    push(@dispatch, 'kb_Bismark' => $obj);
}


my $server = kb_Bismark::kb_BismarkServer->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );

my $handler = sub { $server->handle_input(@_) };

$handler = Plack::Middleware::CrossOrigin->wrap( $handler, origins => "*", headers => "*");
