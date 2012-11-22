# $AICS_Release$
# $AICS_Copyright$
all: add_keywd expand_keywd

add_keywd: add_keywd.pl
	cp add_keywd.pl add_keywd
	chmod a+x add_keywd
	ln -s add_keywd expand_keywd

clean:
	rm expand_keywd add_keywd
