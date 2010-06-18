use v6;

use Test;
use HTTP::Client;

plan 4;

my $client = HTTP::Client.new(:ua("HTTP-Client test"));

my $where = 'http://carlin.theintersect.org/perl6/';

{
# Yuck ... HTTP::Client needs a way to do this itself
my $get = $client.get($where ~ 'index.html').subst(/.*?\n\n/, '').trim;
is $get, "<html><head><title>It works!</title></head><h1>It works!</h1><body></body></html>", 'received correct HTML content'; 
}

{
my $get = $client.get($where ~ 'test.tar').subst(/.*?\n\n/, '');
my $remote-tar = open('test.tar', :w);
$remote-tar.print($get);
$remote-tar.close;
my $local-tar = open('t/files/test.tar', :r);
$remote-tar = open('test.tar', :r);
is $remote-tar.slurp, $local-tar.slurp, 'local and downloaded tar match';
$remote-tar.close;
$local-tar.close;
qqx{tar xf test.tar}; # XXX: Not very portable
ok 'test.txt' ~~ :e, 'tar extracted successfully';
my $local-txt = open('t/files/test.txt', :r);
my $remote-txt = open('test.txt', :r);
is $local-txt.slurp, $remote-txt.slurp, 'local and extracted text files match';
unlink 'test.tar';
unlink 'test.tar';
}
