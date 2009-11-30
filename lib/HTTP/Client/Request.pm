class HTTP::Client::Request;

has Str $.method;
has Str %.uri;
has Str $.headers is rw;
has Str $.content is rw;

method new(Str $method, Str $link) {
	$method ~~ /'GET'|'POST'/ // fail 'Only GET and POST are supported';
	$link ~~ /<URI>/ // fail 'URI is malformed';
	
	my %uri = %( %($/<URI>).kv>>.Str ); # easier to work with a hash of Str
	%uri.push: 'uri', $/<URI>.Str; # might want access to the matched URI
	
	self = self.bless(*, :$method, :%uri);

	# Default headers/content that must be present
	self.add-header-content: "$.method {$.uri<path>} HTTP/1.1";
	self.add-header: 'Host', $.uri<host>;
	self.add-header: 'Connection', 'close';
	
	return self;
}

method set-useragent(Str $useragent) {
	self.add-header: 'User-Agent', $useragent;
}

multi method add-header(Str $name, Str $value) {
	$.headers ~= "$name: $value{crlf}";
}

multi method add-header(Pair $_) {
	self.add-header(.key, .value);
}

method add-header-content(Str $content) {
	$.headers ~= "$content" ~ crlf;
}

sub crlf { return chr(0x0D) ~ chr(0x0A); }

token URI {
	'http://'
	[$<username>=(<-[:@]>*) [':' $<password>=(<-[@]>*)]? '@' ]?
#	[$<username>=(<-[:@]>*)]?
#	[':' $<password>=(<-[@]>*) '@'|'@']?
	$<host>=(<-[:/]>*)
	[':' $<port>=(\d+) ]?
	$<path>=('/' <-[?#]>*)
	['?' $<query>=(<-[#]>*)]?
}

# vim:ft=perl6
