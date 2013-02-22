#!/usr/bin/perl

# $RIKEN_Copyright:$
# $Release_tool_version:$
use strict;
use warnings;
use Data::Dumper;
use Release;

$a = FileToComment("a.c");
print Dumper($a);
print join(' ', GetConfKeywords());
print Dumper(GetConfContents('test'));
exit 0;
