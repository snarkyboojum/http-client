use MIME::Base64;

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

    method basic-authorization(Str :$username, Str :$password) {
        if $username ~~ /\:/ {
            warn "Can't use a username containing ':'";
        }
        my $basic-digest = "Basic " ~ base64encode($username ~ ':' ~ $password);
        %.headers.push: 'Authorization', $basic-digest;
    }

	method add-cookies(Str $headers) {
		for $headers.split("\n") -> $header {
			if $header ~~ /Set\-Cookie\:<ws>(.*?)\=(.*?)\;/ {
				%.cookiejar.push: $0.Str, $1.Str;
			}
		}
	}

	sub format-query(%data) {
        my $formatted-data;
        for %data.kv -> $k, $v {
            $formatted-data ~= "{urlencode($k)}={urlencode($v)}";
        }
        return $formatted-data;
	}

	sub format-cookies(%cookies) {
        my $formatted-cookies;
        for %cookies.kv -> $k, $v {
            $formatted-cookies ~= "$k=$v;";
        }
        return $formatted-cookies;
	}

	sub format-headers(%headers) {
        my $formatted-headers;
        for %headers.kv -> $k, $v {
            $formatted-headers ~= "$k: $v\r\n";
        }
        return $formatted-headers;
	}

	sub urlencode(Str $url) {
        return $url;
		#return $url.subst(/(\W & <-[\.]>)/,
		#	{sprintf('%%%02X', ord($0))}, :g);
	}

    sub base64encode($str) {
        my MIME::Base64 $mime .= new;
        return $mime.encode_base64($str);
    }
}

# vim:ft=perl6
