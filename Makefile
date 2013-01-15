# $AICS_copyright: copyright 2103 RIKEN aics 
# 	All right reserved.$
# $AICS_Release: Released by AICS$
.SUFFIXES: .pl
INSTALL_ROOT = /work/release
all: perllib add_keyword expand_keyword

perllib:
	cd lib;perl Makefile.PL INSTALL_BASE=$(INSTALL_ROOT);make
.pl:
	sed "s,@PERLLIB@,$(INSTALL_ROOT)/lib/perl5," $< > $@
	chmod a+x $@

install:
	cd lib;make install
	[ -d $(INSTALL_ROOT)/bin ] || mkdir $(INSTALL_ROOT)/bin
	install -m 755 add_keyword expand_keyword $(INSTALL_ROOT)/bin
clean:
	cd lib;make distclean
	rm -rf perllib
	rm add_keyword expand_keyword
