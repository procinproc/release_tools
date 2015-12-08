# Copyright (c) 2001,2000,1999,1998,1997
#       Real World Computing Partnership
# Copyright (C) 2003-2011 PC Cluster Consortium
use ExtUtils::MakeMaker;
WriteMakefile(
    'PM_FILTER' => 'sed s,@confpath@,$(INSTALL_BASE)/etc/,',
    'NAME' => 'Release',
    'VERSION' => '0.1',
);
