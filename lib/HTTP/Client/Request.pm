class HTTP::Client::Request;

use HTTP::Client::URI;

has Str $.method;
has Str %.uri;
has Str $.content is rw;
has Str $!headers;
has Str %!header;

method new(Str $method, Str $link) {
	unless $method eq 'GET'|'POST' { die 'Only GET and POST are supported' }
	unless HTTP::Client::URI.parse($link) { die 'URI is invalid' }

	my %uri = %( %($/).kv>>.Str ); # easier to work with a hash of strings
	%uri<uri> = $/.Str; # might want access to the matched URI

	unless %uri<host> { die 'No host was specified' }
	unless %uri<path> { die 'No path was specified' }
	# If a port was specified it would be a string
	unless %uri<port> { %uri<port> = '80'; }

	self .= bless(*, :$method, :%uri);

	# Default headers/content that must be present
	my $location = %.uri<path>;
	if %.uri<query> { $location ~= '?' ~ %.uri<query> }
	self.add-header-content: "$.method $location HTTP/1.1";
	self.add-header: 'Host', %.uri<host>;
	self.add-header: 'Connection', 'close';

	return self;
}

method headers 	{ return $!headers.clone; }
method header 	{ return %!header.clone; }

method user-agent(Str $useragent) {
	self.add-header: 'User-Agent', $useragent;
}

multi method add-header(Str $name, Str $value) {
	self.add-header-content: "$name: $value";
	%!header<<{$name.lc}>> = $value;
}

multi method add-header(Pair $_) {
	self.add-header(.key, .value);
}

method add-header-content(Str $content) {
	$!headers ~= "$content" ~ crlf;
}

sub crlf { return chr(0x0D) ~ chr(0x0A); }

=begin Pod

=head1 HTTP::Client::Request

C<HTTP::Client::Request> is an object representing an HTTP request. It contains
the information that C<HTTP::Client::Response> will use to make the request to
the server.

=head1 Synopsis

This is done for you by HTTP::Client, but you could use it like this:

	my $request = HTTP::Client::Request.new('GET', 'http://example.org/');
	$request.user-agent('My Perl 6 HTTP Client');
	my $response = HTTP::Client::Response.new($request);
	say $response.content;

=head1 Attributes

=over 4

=item $.method

The method of the HTTP request, such as 'GET' or 'POST'.
Is specified and set in the constructor.

=item %.uri

A hash of various parts of the URI as Strings.

protocol, host, path and port are always defined. Other possible keys include:

=over 4

=item protocol

The protocol of the request, such as 'http' or 'https'.
Currently only http is supported

=item username

The username for basic authentication, eg. given http://user@example.org/
the username would be 'user'

=item password

The password for basic authentication, eg. given http://user:pass@example.org/
the password would be 'pass'

=item host

The host of the server, could be a domain name or IP address such as
example.org or 192.0.32.10

=item port

The port to make the request on, eg. given http://example.org:8080/
the port would be '8080'. If no port is specified in the URI the value of this
key defaults to '80'. Note that no matter what this value is a String so when,
for example, calling IO::Socket::INET.open, you will have to cast it to an Int.

=item path

The path of the request, eg. given http://example.org/foo/ the path
would be /foo/.
Note that, given http://example.org/ the path is '/' which means you want
the webserver to return the root page (usually index.something).
A path must be specified, eg. http://example.org is wrong

=item query

The query of the request, eg. given http://example.org/?foo=bar&baz=quux
the query would be 'foo=bar&baz=quux'

=back

=item $.content

The content of the request, usually POST data.

=item $!headers

A String representing the headers, the value of this is sent to the webserver.
The value of this can be accessed using the C<headers> method and can be
modified using the C<add-header> and C<add-header-content> methods.
Not to be confused with the C<%!header> hash.

=item %!header

A hash of the headers. The keys are the header names in lower-case.
Do not confuse with headers (note the 's'). This can be accessed using the
C<header> method and modified the same as $!headers.

=back

=head1 Methods

=over 4

=item new

The constructor. Sets up the attributes and initialises the default headers.
Requires two parameters:

=over 4

=item Str $method

One of 'GET' or 'POST'.

=item Str $uri

The URI of the request.
Must contain a protocol, host and path, eg. in http://example.org/
'http' is the protocol, 'example.org' is the host and '/' is the path.
Remember to include the trailing slash if you want the homepage
http://example.org is wrong.

=back

=item headers

Returns the value of the $!headers attribute. This returns a copy of the
attribute and cannot be used to modify it, this is on purpose to prevent
the $!headers and %!header attributes getting out-of-sync. If you really
need to modify it manually, augment the class and create your own accessor.

	augment HTTP::Client::Request {
		method header-accessor { return $!headers; }
	}

=item header

Returns the value of the %!header attribute. As with C<headers> this return
a copy of the attribute and cannot be used to modify it. The logic behind
calling this C<header> as opposed to C<headers> is that where C<headers> is
always every header in the object, C<header> can be used to access only one
header, eg. $request.header<host> vs $request.headers<host>.

=item user-agent

Sets the user-agent header. An abstraction of set-header('User-Agent', 'Foo').

=item add-header

Adds a header, updating both the $!headers and %!header attributes.
Can be used in two ways:

	add-header('X-Header-Name', 'Foo')
	add-header(X-Header-Name => 'Foo')

=item add-header-content

Adds raw content to the header

=back

=head1 Subroutines

=over 4

=item clrf

Returns a carriage-return and line-feed: "\r\n"

=back

=end Pod

# vim:ft=perl6
