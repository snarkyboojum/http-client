use Test;
use HTTP::Client::Request;
use HTTP::Client::Response;

constant host = 'theintersect.org';
constant port = 80;

{
my $request = HTTP::Client::Request.new('GET', 'http://carlin.theintersect.org/perl6/');
my $response = HTTP::Client::Response.new($request);

my $index-html = open('t/files/index.html', :r).slurp;
is $response.raw-content, $index-html, 'Downloaded index is correct';
}

{
my $request = HTTP::Client::Request.new('GET', 'http://carlin.theintersect.org/perl6/test.tar');
my $response = HTTP::Client::Response.new($request);
my $downloaded-tar = open('test.tar', :w);
$downloaded-tar.print($response.raw-content);
$downloaded-tar = open('test.tar', :r);
my $local-tar = open('t/files/test.tar', :r);
is $downloaded-tar.slurp, $local-tar.slurp, 'Downloaded tar matches local tar';
$downloaded-tar.close;
$local-tar.close;
if $*OS eq 'MSWin32' {
	skip 2, 'Your OS lacks support for these tests';
} else {
	qqx{tar xf test.tar};
	ok 'test.txt' ~~ :e, 'File was extracted from downloaded tar';
	my $downloaded-file = open('test.txt', :r);
	my $local-file = open('t/files/test.txt', :r);
	is $local-file.slurp, $downloaded-file.slurp, 'Extracted file is okay';
	unlink 'test.tar', 'test.txt';
}
}

{
my $request = HTTP::Client::Request.new('GET', 'http://carlin.theintersect.org/perl6/test.pl?test=OHHAI');
my $response = HTTP::Client::Response.new($request);
is $response.raw-content, 'OHHAI', 'Correct GET data passed';
}
