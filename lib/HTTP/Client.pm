class HTTP::Client;

use HTTP::Client::Request;
use HTTP::Client::Response;
use HTTP::Client::Cookies;

has Str $.useragent is rw = '';
has HTTP::Client::Cookies $.cookiejar = HTTP::Client::Cookies.new; # XXX RAKUDO

method get(Str $uri) {
	my $request = HTTP::Client::Request.new('GET', $uri);
	$request.set-useragent($.useragent);
	return $request;
}

# vim:ft=perl6
