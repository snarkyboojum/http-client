grammar HTTP::Client::URI;

token TOP { <protocol> '://' [<username> [':' <password>]? '@' ]?
	<host> [':' <port>]? <path> ['?' <query>]? }

token protocol 	{ 'http' 	} # only http is supported at the moment
token username 	{ <-[:@]>* 	}
token password 	{ <-[@]>* 	}
token host	{ <-[:/]>* 	}
token port	{ \d*		}
token path	{ <-[#?]>*	}
token query	{ <-[#]>*	}
# token anchor	{ .*		} we don't worry about the anchor text

=begin Pod

=head1 URI

This is a URI grammar for use with HTTP::Client.

It is very liberal in what it accepts in a URI as it better to allow bad URIs
to parse rather than have valid URIs fail.

=end Pod

# vim:ft=perl6
