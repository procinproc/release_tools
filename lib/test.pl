#!/usr/bin/perl

# $AICS_copyright:$
# $AICS_Release:$
use strict;
use warnings;
use Data::Dumper;
use Release qw(ReadConf FileToComment);
use vars qw(%config $a);

$a = FileToComment("a.c");
print Dumper($a);
%config = ReadConf("test.conf");
print Dumper(%config);
exit 0;