# $RIKEN_Copyright:$
# $Release_tool_version:$
.SUFFIXES: .pl
INSTALL_ROOT = /work/release
all: perllib add_keyword expand_keyword

perllib:
	cd lib;perl Makefile.PL INSTALL_BASE=$(INSTALL_ROOT);make
.pl:
	sed -e "s,@PERLLIB@,$(INSTALL_ROOT)/lib/perl5," \
	-e "s,@PERLETC@,$(INSTALL_ROOT)/etc," $< > $@
	chmod a+x $@

install:
	cd lib;make install
	[ -d $(INSTALL_ROOT)/bin ] || mkdir $(INSTALL_ROOT)/bin
	[ -d $(INSTALL_ROOT)/etc ] || mkdir $(INSTALL_ROOT)/etc
	install -m 755 add_keyword expand_keyword $(INSTALL_ROOT)/bin
	install -m 755 release.conf $(INSTALL_ROOT)/etc
clean:
	cd lib;make distclean
	rm add_keyword expand_keyword
