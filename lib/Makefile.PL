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
use ExtUtils::MakeMaker;
WriteMakefile(
    'PM_FILTER' => 'sed s,@confpath@,$(INSTALL_BASE)/etc/,',
    'NAME' => 'Release',
    'VERSION' => '0.1',
);
