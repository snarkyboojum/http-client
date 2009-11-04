use v6;

BEGIN { @*INC.push: 'lib' }

use HTTP::Client;

my $http = HTTP::Client.new(
	:ua('HTTP-Client +http://github.com/carlins/http-client'));

my $data = $http.get('http://github.com/carlins/http-client');

say $data;
