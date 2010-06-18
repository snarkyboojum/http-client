PERL6=perl6
PERL6LIB='/Users/adrian/Development/Perl6/http-client/lib'

SOURCES=lib/HTTP/Client.pm

PIRS=$(patsubst %.pm6,%.pir,$(SOURCES:.pm=.pir))

.PHONY: test clean

all: $(PIRS)

%.pir: %.pm
	env PERL6LIB=$(PERL6LIB) $(PERL6) --target=pir --output=$@ $<

%.pir: %.pm6
	env PERL6LIB=$(PERL6LIB) $(PERL6) --target=pir --output=$@ $<

clean:
	rm -f $(PIRS)

test: all
	env PERL6LIB=$(PERL6LIB) prove -e '$(PERL6)' -r --nocolor t/

install: all
	install -D lib/HTTP/Client.pir ~/.perl6/lib/HTTP/Client.pir

install-src:
	install -D lib/HTTP/Client.pm ~/.perl6/lib/HTTP/Client.pm
