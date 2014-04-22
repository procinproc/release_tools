# Copyright (c) 2001,2000,1999,1998,1997
#       Real World Computing Partnership
# Copyright (C) 2003-2011 PC Cluster Consortium
# $RIKEN_copyright: Copyright 2013-2014 RIKEN All rights reserved.$
# $LGPL2:  This library is free software; you can redistribute it and/or 
#     modify it under the terms of the GNU Lesser General Public 
#     License as published by the Free Software Foundation; either 
#     version 2 of the License, or (at your option) any later version. 
#  
#     This library is distributed in the hope that it will be useful, 
#     but WITHOUT ANY WARRANTY; without even the implied warranty of 
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
#     Lesser General Public License for more details. 
#  
#     You should have received a copy of the GNU Lesser General Public 
#     License along with this library; if not, write to the Free Software 
#     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA $
# $RELEASE_TOOL_VERSION: 0.32$
.SUFFIXES: .pl
INSTALL_ROOT = /work/release
CONF_FILES = copyright.conf license.conf
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
	install -m 755 $(CONF_FILES) $(INSTALL_ROOT)/etc
clean:
	-cd lib;$(MAKE) distclean
	rm -f add_keyword expand_keyword
distclean: clean
release: install
	$(INSTALL_ROOT)/bin/expand_keyword -config copyright.conf,license.conf,reltool.conf -tag riken,lgpl2,reltool .

