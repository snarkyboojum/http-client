grammar URL {
	rule TOP { <prefix> <host> <uri> }
	rule prefix { http\:\/\/ }
	rule host { <-[/]>* }
	rule uri { .* }
}

class HTTP::Client {
	has $!ua;
	has %.cookiejar is rw;
	has %.headers is rw;

	submethod BUILD(Str :$ua) {
		$!ua = $ua || 'Perl6';
	}

	method post(Str $url, %data) {
		my $post-data = format-query(%data);
		%.headers.push: 'Content-Length', $post-data.chars.Str;
		%.headers.push: 'Content-Type',
			'application/x-www-form-urlencoded';
		my %request = self.prepare-request('POST', $url);
		%request<headers> ~= "\r\n$post-data\r\n";
		return self.request(%request<host>, %request<headers>);
	}

	multi method get(Str $url, %data) {
		return self.get($url ~ '?' ~ format-query(%data));
	}

	multi method get(Str $url) {
		my %request = self.prepare-request('GET', $url);
		return self.request(%request<host>, %request<headers>);	
	}

	method request(Str $server, Str $headers) {
		my $socket = IO::Socket::INET.new;
		$socket.open($server, 80);
		$socket.send("$headers\r\n");
		return $socket.recv();
	}

	method prepare-headers(Str $server) {
		my %headers = { Host => $server,
			User-Agent => $!ua, Connection => 'close' };
		%headers.push('Cookie',
			format-cookies(%.cookiejar)) if %.cookiejar;
		%headers.push: %.headers if %.headers;
		%.headers = {};
		return %headers;
	}

	method prepare-request(Str $method, Str $url) {
		URL.parse($url);
		my $headers = "$method {$/<uri>.Str} HTTP/1.1\r\n";
		$headers ~= format-headers(self.prepare-headers($/<host>.Str));
		return { headers => $headers, host => $/<host>.Str };
	}	

	method add-cookies(Str $headers) {
		for $headers.split("\n") -> $header {
			if $header ~~ /Set\-Cookie\:<ws>(.*?)\=(.*?)\;/ {
				%.cookiejar.push: $0.Str, $1.Str;
			}
		}
	}

	sub format-query(%data) {
		return (map { "{urlencode(.key)}={urlencode(.value)}&" },
			%data).join.chop;
	}

	sub format-cookies(%cookies) {
		return (map { "{.key}={.value};" }, %cookies).Str;
	}

	sub format-headers(%headers) {
		return (map { "{.key}: {.value}\r\n" },%headers).join;
	}

	sub urlencode(Str $url) {
		return $url.subst(/(\W & <-[\.]>)/,
			{sprintf('%%%02X', ord($0))}, :g);
	}
}

# vim:ft=perl6
