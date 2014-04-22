#!/usr/bin/perl

# $RIKEN_copyright: Copyright 2013-2014 RIKEN All rights reserved.$
# $RIKEN_copyright: Copyright 2013-2014 RIKEN All rights reserved.$
# $GPL2: This program is free software; you can redistribute it and/or 
# modify it under the terms of the GNU General Public License 
# as published by the Free Software Foundation; either version 2 
# of the License, or (at your option) any later version. 
#  
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
# GNU General Public License for more details. 
#  
# You should have received a copy of the GNU General Public License 
# along with this program; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.$
# $RELEASE_TOOL_VERSION: 0.32$
# $RELEASE_TOOL_VERSION: 0.32$

use strict;
use warnings;
use Data::Dumper;
use Release;

$a = FileToComment("a.c");
print Dumper($a);
print join(' ', GetConfKeywords());
print Dumper(GetConfContents('test'));
exit 0;
