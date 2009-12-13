class IO::Socket::INET is also {
	# XXX Temporary
	method get (Str $separator) {
		fail ("Not connected") unless $!PIO;
		my $position;
		loop {
			$position = $!buffer.index($separator);
			last if $position.defined;
			$!buffer ~= $!PIO.recv();
		}
		my $received = $!buffer.substr(0, $position);
		$!buffer .= substr($position + $separator.chars);
		return $received;
	}
}

class HTTP::Client::Response;

has $.request;
has Str $.raw-content;
has Str $.raw-headers;

has Str %!headers;
has Str $!protocol;
has Str $!code;
has Str $!message;

method new($request) {
	my $socket = IO::Socket::INET.new;
	$socket.open($request.uri<host>, $request.uri<port>.Int);
	$socket.send($request.headers ~ "\r\n");
	self.bless(*,
		:$request,
		raw-headers => $socket.get("\r\n\r\n"),
		raw-content => $socket.recv,
	);
}

method headers {
	unless %!headers {
		my @headers = $.raw-headers.split("\r\n");
		for @headers {
			my ($name, $value) = .split(/':'\s+/, 2);
			%!headers.push: $name.lc, $value;
		}
	}
	return %!headers;
}

method protocol { self!first-line unless $!protocol; return $!protocol; }
method code 	{ self!first-line unless $!code; return $!code; 	}
method message 	{ self!first-line unless $!message; return $!message; 	}

method !first-line {
	($!protocol, $!code, $!message) = $.raw-headers.split("\r\n")\
		.shift.split(' ', 3);
}

# vim:ft=perl6
