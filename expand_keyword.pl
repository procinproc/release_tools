#!/usr/bin/perl

# $AICS_copyright:$
# $AICS_Release:$
use lib qw(@PERLLIB@);
use Getopt::Long;
use File::Find;
use File::Temp qw(tempfile);
use Release;
use Data::Dumper;
use strict;
use warnings;
use vars qw($help %config $config @tag @key_contents $t);

$config = "release.conf";
@key_contents = ();
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
    my($file, $key_contents) = @_;
    my($tmpfile, $OUT);
    my($dev, $ino, $mode);
    my(@key_contents) = @$key_contents;
    open(IN, "<$file") || print "can't open $file.\n";
    ($dev, $ino, $mode) = stat(IN);
    ($OUT, $tmpfile) = tempfile();
    while(<IN>) {
        my($line, $kc, $replaced);
	$replaced = 0;
	foreach $kc (@key_contents) {
	   my($k) = $kc->{"keyword"};
	   my($c) = $kc->{"contents"};
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


sub Usage {
    print(STDOUT "usage:\n");
    print(STDOUT "\t$0 -help\n");
    print(STDOUT "\t\tor\n");
    print(STDOUT "\t$0 -config config_file [-tag tag] files ...\n");
}


sub ErrorExit {
    my($stat, $mes) = @_;
    print(STDERR "Error: $mes\n");
    &Usage();
    exit($stat);
}


sub ArgCheck {
    if ($help) {
	&Usage();
	exit(0);
    }
    if (!@ARGV) {
	&ErrorExit(1, "No files are specified.");
    }
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
   ExpandHeader($i, \@key_contents) if(defined($comment));
}

GetOptions("config=s" => \$config, "tag=s" => \@tag, "help" => \$help);
@tag = split(/,/, join(',', @tag));

ArgCheck();
%config = ReadConf($config);

if(@tag) {
    foreach $t (@tag) {
	my($c) = $config{$t};
        push(@key_contents, @$c); 
    }
} else {
    foreach $t (keys %config) {
	my($c) = $config{$t};
        push(@key_contents, @$c); 
    }
}

    
find({wanted => \&wanted}, @ARGV);
exit(0);
