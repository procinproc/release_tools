#!/usr/bin/perl

# $RIKEN_copyright: Copyright 2015 RIKEN All rights reserved.$

# Copyright (c) 2001,2000,1999,1998,1997
#       Real World Computing Partnership
# Copyright (C) 2003-2011 PC Cluster Consortium

use lib qw(@PERLLIB@);
use Getopt::Long qw(:config pass_through);
use File::Find;
use File::Temp qw(tempfile);
use Release;
use Data::Dumper;
use strict;
use warnings;
use vars qw(@keywords $t $verbose);

$verbose = 0;

sub match_1st {
    my($expr, $file) = @_;
    open(IN, "<$file");
    while (<IN>) {
	if(/$expr/) {
	    close(IN);
	    return $_;
	}
    }
    close(IN);
    return undef;
}

sub GetFileName {
    my($name) = @_;
    my(@list) = split(/\//, $name);
    return pop(@list);
}

sub GetSuffix {
    my($file) = GetFileName(@_);
    my($suffix) = $file =~ /(\.[^.]*)$/;
    return $suffix;
}

sub ExpandHeader {
    my($file, @keywords) = @_;
    my($tmpfile, $OUT);
    my($dev, $ino, $mode);
    open(IN, "<$file") || die "can't open $file.\n";
    ($dev, $ino, $mode) = stat(IN);
    ($OUT, $tmpfile) = tempfile();
    while(<IN>) {
        my($line, $k, $replaced);
	$replaced = 0;
	foreach $k (@keywords) {
	   my($c) = GetConfContents($k);
	   if(/^(.*)\$\s*$k([^\$]*\$?)(.*)$/) {
	      my ($pre) = $1;
	      my ($m) = $2;
	      my ($post) = $3;
	      if ($c =~ /%y/) {
	          my($y) = $m =~ /([\d,-]+)/;
		  $y = addyear($y);
		  $c =~ s/%y/$y/;
	      }
	      print $OUT $pre;
	      print $OUT "\$$k: ";
	      $c =~ s/\n/\n$pre/g;
	      print $OUT $c;
	      print $OUT "\$";
	      if($m =~ /\$$/) {
	          print $OUT "$post\n";
	      } else {
	          while(<IN>) {
		     next if(! /\$/);
		     s/^[^\$]*\$//;
		     last;
		  }
		  print $OUT "\n";
	      }
	      $replaced = 1;
	      next;
	   }
	}
	print $OUT $_ if($replaced == 0);
    }
    close($OUT);
    close(IN);
    rename($tmpfile, $file) || system("mv $tmpfile $file") == 0 ||
        die "can't rename from $tmpfile to $file";
    chmod($mode, $file) || die "can't chmod $file";
}

sub wanted {
   my ($save) = $_;
   my ($i) = $save;

   /^CVS(ROOT)?$/ && ($File::Find::prune = 1, return);
   /^.git$/ && ($File::Find::prune = 1, return);
   return if (-d $_);
   return if (/\.gif$/);
   return if (/\.jpg$/);
   return if (/\.png$/);
   return if (/\.gz$/);
   process_file($i);
   $_ = $save;
}

sub process_file {
   my($i) = $_;
   my ($comment);

   print "Process: $i\n" if($verbose);
   $comment = FileToComment($i);
   ExpandHeader($i,@keywords) if(defined($comment));
}

GetOptions("verbose" => \$verbose);
@keywords = GetConfKeywords();
find({wanted => \&wanted}, @ARGV);
exit(0);
__END__
=pod
=head1 NAME

expand_keyword - Expand keyword into source files for release.

=head1 SYNOPSIS

expand_keyword [-config configfiles] [-tag tags] [-year year] file file...

=head1 DESCRIPTION

C(expand_keyword) insert text for specific bkeywords in the files.
The keywords are specifies config files and tags.
The keywords are inserted in the comment.

=head2 options

=over

=item -config configfiles
Specify config files.
If you want to use multiple files, please separate "," to the filenames.
The filename serched to the path to environment variable RELTOOL_PATH.
If the environment variable is not set, search @PERLETC@ and current directory.

If -config options is not specified, expand_keyword use environment variable
RELTOOL_COMF.

=item -tag tags

Specify tag for the keywords.
If you want to use multiple tags, please separate "," to the tag.
If tag is specified, all keyword in the config files are used.

=item -year year

Specify year to replace %y to current year.

=item file

The file to insert text can specifies multiple files.
If you specify directory, all files into the directory is used.

=back

expand_keyword inserted text only known language by the add_keyword.
If you want to add language, please modify Release module.

=head1 SEE ALSO

expand_keyword(1),
release_config(5).
=cut
