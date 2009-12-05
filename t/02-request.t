use v6;
use Test;
use HTTP::Client::Request;

plan *;

=begin Pod

=head1 HTTP::Client::Request tests

This file provides tests for HTTP::Client::Request

It contains a helper class, C<RequestTest>, which provides methods which
test the URI elements against what is used in the majority of test cases.
This is to reduce code duplication when testing various URI formats.

=end Pod

class RequestTest {
	has $.r;
	has $!message;
	has $.protocol = 'http';
	has $.username = 'user';
	has $.password = 'pass';
	has $.host = 'example.org';
	has $.port = '8080';
	has $.path = '/path/to/file.pl';
	has $.query = 'query=value&foo=corge';
	has $.anchor = 'ignore';

	method new($request, $message) {
		return self.bless(*, r => $request, :$message);
	}

	method object_ok {
		ok $.r, $!message ~ ' - Request object is okay';
	}
	method protocol_ok {
		is $.r.uri<protocol>, $.protocol, 'Protocol is correct';
	}
	method username_ok {
		is $.r.uri<username>, $.username, 'Username is correct';
	}
	method password_ok {
		is $.r.uri<password>, $.password, 'Password is correct';
	}
	method host_ok {
		is $.r.uri<host>, $.host, 'Host is correct';
	}
	method port_ok {
		is $.r.uri<port>, $.port, 'Port is correct';
	}
	method path_ok {
		is $.r.uri<path>, $.path, 'Path is correct';
	}
	method query_ok {
		is $.r.uri<query>, $.query, 'Query is correct'; 
	}
	method uri_ok($u) {
		is $.r.uri<uri>, $u, 'Matched URI is correct';
	}
}

my $link; # call this $link so the tests can have $uri - XXX temp would help

{
# The defaults are defined as attributes in RequestTest so construct the main
# URI from there. This allows the URI to be easily modified later.

$_ = RequestTest.new('',''); # it needs 2 params, doesn't matter what they are

$link = "{.protocol}://{.username}:{.password}@{.host}:{.port}{.path}?{.query}" ~ "#{.anchor}"; # XXX "{...}#{...}" causes an 'embedded comments' error
}

{ # Full URI test
my $uri = $link;
my $request = HTTP::Client::Request.new('GET', $uri);
my $req = RequestTest.new($request, 'Full URI test');
$req.object_ok;
$req.protocol_ok;
$req.username_ok;
$req.password_ok;
$req.host_ok;
$req.port_ok;
$req.path_ok;
$req.query_ok;
$req.uri_ok($uri.substr: 0, -7);
}

{ # URI with an incorrect protocol
my $uri = 'ssh://theintersect.org/';
eval_dies_ok "HTTP::Client::Request.new('GET', $uri)",'Wrong protocol is fatal';
}

{ # URI without pass
my $uri = $link.subst(':' ~ .password, '');
my $request = HTTP::Client::Request.new('GET', $uri);
my $req = RequestTest.new($request, 'URI without a password');
$req.object_ok;
$req.protocol_ok;
$req.username_ok;
is $req.r.uri<password>, undef, 'Password is undefined';
$req.host_ok;
$req.port_ok;
$req.path_ok;
$req.query_ok;
$req.uri_ok($uri.substr: 0, -7);
}

{ # URI without a username (or password)
my $uri = $link.subst(.username ~ ':' ~ .password ~ '@', '');
my $request = HTTP::Client::Request.new('GET', $uri);
my $req = RequestTest.new($request, 'URI without a username');
$req.object_ok;
$req.protocol_ok;
is $req.r.uri<username>, undef, 'Username is undefined';
is $req.r.uri<password>, undef, 'Password is undefined';
$req.host_ok;
$req.port_ok;
$req.path_ok;
$req.query_ok;
$req.uri_ok($uri.substr: 0, -7);
}

{ # URI without a host
my $uri = $link.subst(.host, '');
eval_dies_ok "HTTP::Client::Request.new('GET',$uri)", 'URI without a host dies';
}

{ # URI without a password, username or port
my $uri = $link.subst(.username ~ ':' ~ .password ~ '@', '');
$uri .= subst(':' ~ .port, '');
my $request = HTTP::Client::Request.new('GET', $uri);
my $req = RequestTest.new($request, 'URI without a port');
$req.object_ok;
$req.protocol_ok;
is $req.r.uri<username>, undef, 'Username is undefined';
is $req.r.uri<password>, undef, 'Password is undefined';
$req.host_ok;
is $req.r.uri<port>, '80', 'Port defaults to 80 if not specified';
$req.path_ok;
$req.query_ok;
$req.uri_ok($uri.substr: 0, -7);
}

{ # URI without a path
my $uri = $link.subst(.path, '');
eval_dies_ok "HTTP::Client::Request.new('GET',$uri)", 'URI without a path dies';
}

{ # URI with path as /
my $uri = $link.subst(.path, '/');
my $request = HTTP::Client::Request.new('GET', $uri);
my $req = RequestTest.new($request, 'URI with path as /');
$req.object_ok;
$req.protocol_ok;
$req.username_ok;
$req.password_ok;
$req.host_ok;
$req.port_ok;
is $req.r.uri<path>, '/', 'Path is /';
$req.query_ok;
$req.uri_ok($uri.substr: 0, -7);
}

{ # URI without a password, username, port or query
my $uri = $link.subst(.username ~ ':' ~ .password ~ '@', '');
$uri .= subst(':' ~ .port, '');
$uri .= subst('?' ~ .query, '');
my $request = HTTP::Client::Request.new('GET', $uri);
my $req = RequestTest.new($request, 'URI without a query');
$req.object_ok;
$req.protocol_ok;
is $req.r.uri<username>, undef, 'Username is undefined';
is $req.r.uri<password>, undef, 'Password is undefined';
$req.host_ok;
is $req.r.uri<port>, '80', 'Port defaults to 80 if not specified';
$req.path_ok;
is $req.r.uri<query>, undef, 'Query is undefined';
$req.uri_ok($uri.substr: 0, -7);
}

{ # URI with everything but a query
my $uri = $link.subst('?' ~ .query, '');
my $request = HTTP::Client::Request.new('GET', $uri);
my $req = RequestTest.new($request, 'URI without a query');
$req.object_ok;
$req.protocol_ok;
$req.username_ok;
$req.password_ok;
$req.host_ok;
$req.port_ok;
$req.path_ok;
is $req.r.uri<query>, undef, 'Query is undefined';
$req.uri_ok($uri.substr: 0, -7);
}

{ # URI with only a protocol, host and path
my $uri = "{.protocol}://{.host}{.path}";
my $request = HTTP::Client::Request.new('GET', $uri);
my $req = RequestTest.new($request, 'URI with only the bare-bones');
;$req.object_ok;
$req.protocol_ok;
is $req.r.uri<username>, undef, 'Username is undefined';
is $req.r.uri<password>, undef, 'Password is undefined';
$req.host_ok;
is $req.r.uri<port>, '80', 'Port is default';
$req.path_ok;
is $req.r.uri<query>, undef, 'Query is undefined';
$req.uri_ok($uri);
}

{ # URI with only a protocol, host, path and port
my $uri = "{.protocol}://{.host}:4242{.path}";
my $request = HTTP::Client::Request.new('GET', $uri);
my $req = RequestTest.new($request, 'URI with the bare-bones and port');
$req.object_ok;
$req.protocol_ok;
is $req.r.uri<username>, undef, 'Username is undefined';
is $req.r.uri<password>, undef, 'Password is undefined';
$req.host_ok;
is $req.r.uri<port>, '4242', 'Port is correct';
$req.path_ok;
is $req.r.uri<query>, undef, 'Query is undefined';
$req.uri_ok($uri);
}

# TODO more URI permutations could be tested

{
ok "HTTP::Client::Request.new('GET', '')", 'GET is an accepted method';
ok "HTTP::Client::Request.new('POST', '')", 'POST is an accepted method';
eval_dies_ok "HTTP::Client::Request.new('NO', '')", 'Unknown methods are fatal';
}

{ # modifying headers
my $request = HTTP::Client::Request.new('GET', 'http://theintersect.org/');
is $request.header<host>, 'theintersect.org', 'Got default header';
is $request.headers, "GET / HTTP/1.1\r\nHost: theintersect.org\r\nConnection: close\r\n", 'Got the default headers';
$request.add-header('X-Jabberwock', 'twas brillig');
is $request.header<x-jabberwock>, 'twas brillig', 'Got set header';
ok $request.headers ~~ /'X-Jabberwock: twas brillig'/, 'Found set header';
$request.add-header: (Y-Jabberwock => 'slithy toves');
is $request.header<y-jabberwock>, 'slithy toves', 'Got header set with pair';

$request.add-header('FoObArBaZ', 'Quux Corge');
is $request.header<foobarbaz>, 'Quux Corge',
	'Header names are lowercased in the hash';
ok $request.headers ~~ /'FoObArBaZ: Quux Corge'/,
	'Header names are added verbatim to the string';

$request.headers = 'Foobar';
isnt $request.headers, 'Foobar', 'Assigning to headers has no effect';
$request.header<host> = 'example.org';
is $request.header<host>,'theintersect.org','Assigning to header has no effect';

$request.user-agent('Jubjub bird');
is $request.header<user-agent>, 'Jubjub bird', 'User-Agent is set';
ok $request.headers ~~ /'User-Agent: Jubjub bird'/,
	'User-Agent has correct casing in the string';
nok $request.headers ~~ /'user-agent'/, 'Correct casing in string';

$request.add-header-content('The Jabberwock, with eyes of flame');
ok $request.headers ~~ /'The Jabberwock, with eyes of flame'\r\n/,
	'Found added header content followed by a crlf';
}

{
my $request = HTTP::Client::Request.new('POST', 'http://theintersect.org/');
is $request.header<host>, 'theintersect.org', 'Got default header';
is $request.headers, "POST / HTTP/1.1\r\nHost: theintersect.org\r\nConnection: close\r\n", 'Got the default POST headers';
}

is HTTP::Client::Request::crlf, "\r\n",
	'crlf returns a carriage return and line feed';

done_testing;

# vim:ft=perl6
