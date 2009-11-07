use v6;

use Test;
use HTTP::Client;

plan 23;

=begin Pod

These are tests for the formatting related functions eg. checking that headers
etc. are stringified correctly.

=end Pod

my $client = HTTP::Client.new(:ua("BasicClient Test"));

ok $client, 'object created';

is HTTP::Client::urlencode('f!o@#+b$%.^a& *r/\\baz'), 'f%21o%40%23%2Bb%24%25.%5Ea%26%20%2Ar%2F%5Cbaz', 'urlencode correctly hexified the string';

ok HTTP::Client::format-headers({ Host => 'theintersect.org', User-Agent => 'BasicClient Test' }) ~~ /Host\:<ws>theintersect\.org\n/, 'format-headers formatted correctly';

ok HTTP::Client::format-headers({ Host => 'theintersect.org', User-Agent => 'BasicClient Test' }) ~~ /User\-Agent\:<ws>BasicClient<ws>Test\n/, 'format-headers formatted correctly';

ok HTTP::Client::format-cookies({ Foobar => 'lorem', Bazqux => 'ipsum' }) ~~ /(Foobar\=lorem\;<ws>Bazqux\=ipsum\;) || (Bazqux\=ipsum\;<ws>Foobar\=lorem\;)/, 'format-cookies formatted correctly';

is HTTP::Client::format-query({ token => 'foobar+\\' }), 'token=foobar%2B%5C', 'format-query correctly formats and urlencodes';

ok HTTP::Client::format-query({ Foobar => 'lorem', Bazqux => 'ip&sum' }) ~~ /(Foobar\=lorem\&Bazqux\=ip\%26sum) || (Bazqux\=ip\%26sum\&Foobar\=lorem)/, 'format-query formatted and handles & correctly';

{
# A real-world like HTTP response
my $h = "HTTP/1.1 200 OK
Server: Apache
Set-Cookie: centralauth_User=Foobar; expires=Sun, 07-Feb-2010 07:02:19 GMT; path=/; domain=.example.org; httponly
Set-Cookie: centralauth_Token=3d8f6cad8a0176f20519d2e2e68b8efd; expires=Sun, 07-Feb-2010 07:02:19 GMT; path=/; domain=.example.org; httponly
Set-Cookie: enwikiUserID=3133742; expires=Sun, 07-Feb-2010 07:02:19 GMT; path=/; httponly
Content-Language: en
Vary: Accept-Encoding,Cookie
Content-Type: text/html; charset=utf8
Connection: keep-alive\n\n";

$client.add-cookies($h);

is +$client.cookiejar, 3, 'add-cookies added the correct number of cookies';
ok $client.cookiejar.exists('centralauth_User'), 'centralauth_User cookie exists';
ok $client.cookiejar.exists('centralauth_Token'), 'centralAuth_Token cookie exists';
ok $client.cookiejar.exists('enwikiUserID'), 'enwikiUserID cookie exists';

is $client.cookiejar<centralauth_User>, 'Foobar', 'centralauth_User cookie contains the right value';
is $client.cookiejar<centralauth_Token>, '3d8f6cad8a0176f20519d2e2e68b8efd', 'centralauth_Token cookie contains the right value';
is $client.cookiejar<enwikiUserID>, '3133742', 'enwikiUserID cookie contains the right value';
}

{
my $p = $client.prepare-request('GET', 'http://theintersect.org/about/');
is $p<host>, 'theintersect.org', 'prepare-request returned the correct host';
ok $p<headers> ~~ /\/about\//, 'prepare-request returned the correct uri';
}

{
$client.headers.push: 'X-Testing', 'foo';
$client.headers.push: 'X-Foobar', 'test';
my $p = $client.prepare-headers('theintersect.org');
is $p<Host>, 'theintersect.org', 'prepare-headers returned the correct host';
is $p<User-Agent>, 'BasicClient Test', 'prepare-headers returned the correct ua';
ok $p<Cookie> ~~ /enwikiUserID\=3133742\;/, 'prepare-headers contains enwikiUserID cookie';
ok $p<Cookie> ~~ /centralauth_Token\=3d8f6cad8a0176f20519d2e2e68b8efd\;/, 'prepare-headers contains centralauth_Token cookie';
ok $p<Cookie> ~~ /centralauth_User\=Foobar\;/, 'prepare-headers contains central_User cookie';

is $p<X-Testing>, 'foo', 'prepare-headers added the X-Testing header from %.headers';
is $p<X-Foobar>, 'test', 'prepare-headers added the X-Foobar header from %.headers';
}

# vim:ft=perl6
