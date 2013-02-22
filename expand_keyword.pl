#!/usr/bin/perl

# $RIKEN_Copyright:$
# $Release_tool_version:$

use lib qw(@PERLLIB@);
use Getopt::Long;
use File::Find;
use File::Temp qw(tempfile);
use Release;
use Data::Dumper;
use strict;
use warnings;
use vars qw(@keywords $t);

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
    open(IN, "<$file") || print "can't open $file.\n";
    ($dev, $ino, $mode) = stat(IN);
    ($OUT, $tmpfile) = tempfile();
    while(<IN>) {
        my($line, $k, $replaced);
	$replaced = 0;
	foreach $k (@keywords) {
	   my($c) = GetConfContents($k);
	   if(/^(.*)\$\s*$k([^\$]*\$)(.*)$/) {
	      my ($pre) = $1;
	      my ($m) = $2;
	      my ($post) = $3;
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
		     s/^[^\$]*//;
		     print $OUT "$_\n";
		  }
	      }
	      $replaced = 1;
	      last;
	   }
	}
	next if($replaced);
	print $OUT $_;

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

   print "Process: $i\n";
   $comment = FileToComment($i);
   ExpandHeader($i,@keywords) if(defined($comment));
}

@keywords = GetConfKeywords();
find({wanted => \&wanted}, @ARGV);
exit(0);
