use v6;
use Test;
use HTTP::Client::Request;

=begin Pod

=head1 HTTP::Client::Request tests

This file provides tests for HTTP::Client::Request

It contains a helper class, C<RequestTest>, which provides methods which
test the URI elements against what is used in the majority of test cases.
This is to reduce code duplication when testing various URI formats.

=end Pod

class RequestTest {
	has $!r;
	has $!message;
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
		ok $!r, $!message ~ ' - Request object is okay';
	}
	method username_ok {
		is $!r.uri<username>, $.username, 'Username is correct';
	}
	method password_ok {
		is $!r.uri<password>, $.password, 'Password is correct';
	}
	method host_ok {
		is $!r.uri<host>, $.host, 'Host is correct';
	}
	method port_ok {
		is $!r.uri<port>, $.port, 'Port is correct';
	}
	method path_ok {
		is $!r.uri<path>, $.path, 'Path is correct';
	}
	method query_ok {
		is $!r.uri<query>, $.query, 'Query is correct'; 
	}
	method uri_ok($u) {
		is $!r.uri<uri>, $u, 'Matched URI is correct';
	}
}

my $link; # call this $link so the tests can have $uri - XXX temp would help

{
# The defaults are defined as attributes in RequestTest so construct the main
# URI from there. This allows the URI to be easily modified later.

$_ = RequestTest.new('',''); # it needs 2 params, doesn't matter what they are

$link = "http://{.username}:{.password}@{.host}:{.port}{.path}?{.query}" ~
	"#{.anchor}"; # XXX "{...}#{...}" causes an 'embedded comments' error
}

{ # Full URI test
my $uri = $link;
my $request = HTTP::Client::Request.new('GET', $uri);
my $req = RequestTest.new($request, 'Full URI test');
$req.object_ok;
$req.username_ok;
$req.password_ok;
$req.host_ok;
$req.port_ok;
$req.path_ok;
$req.query_ok;
$req.uri_ok($uri.substr: 0, -7);
}

{ # URI without pass
my $uri = $link.subst(':' ~ .password, '');
my $request = HTTP::Client::Request.new('GET', $uri);
my $req = RequestTest.new($request, 'URI without a password');
$req.object_ok;
$req.username_ok;
#$req.password_ok;
$req.host_ok;
$req.port_ok;
$req.path_ok;
$req.query_ok;
$req.uri_ok($uri.substr: 0, -7);
}

{ # URI without a username 
my $uri = $link.subst(.username ~ ':' ~ .password ~ '@', '');
my $request = HTTP::Client::Request.new('GET', $uri);
my $req = RequestTest.new($request, 'URI without a useraname');
$req.object_ok;
$req.username_ok;
#$req.password_ok;
$req.host_ok;
$req.port_ok;
$req.path_ok;
$req.query_ok;
$req.uri_ok($uri.substr: 0, -7);
}


# vim:ft=perl6
