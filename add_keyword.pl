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
use vars qw($help %config $config @tag @keyword $t);

$config = "release.conf";
@keyword = ();
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

sub PutHeader {
    my ($file, $keywords, %com) = @_;
    my ($start) = $com{"start"};
    my ($cont) = $com{"cont"};
    my ($end) = $com{"end"};
    my ($tmpfile);
    my ($sufix) = GetSuffix($file);
    my ($key);
    my(@keywords) = @$keywords;
    my($k, $OUT);

    if (! -e $file ) {
	open(NEW, ">$file");
	close(NEW);
    }
    @keywords = grep {my($save) = $_;match_1st($_, $file);$_ = (defined($_))? undef: $save} @keywords;
    my ($HaveSharpExcram) = match_1st('^\s*#\s*!', $file);
    my ($HavePercentRoundBrace);
    if (defined($sufix) && ($sufix eq ".l" || $sufix eq ".y")) {
	$HavePercentRoundBrace = match_1st('^\s*\%\s*\{', $file);
    }
    my ($IsMultilineComment) = ($start ne $cont) ? 1 : 0;
    my($In_comment) = 0;


    return if(!@keywords);

    ($OUT, $tmpfile) = tempfile();
    
    if (!$IsMultilineComment) {
	if ($HaveSharpExcram) {
	    print($OUT "$HaveSharpExcram\n");
	}
    }

    if ($HavePercentRoundBrace) {
	print($OUT "$HavePercentRoundBrace\n");
    }


    if ($IsMultilineComment) {
	print($OUT "$start\n");
    }

    foreach $key (@keywords) {
	print($OUT $cont . "\$$key:\$\n");
    }

    if ($IsMultilineComment) {
	print($OUT $end . "\n");
    }

    open(IN, "<$file") || die "can't open $file.\n";

    my ($dev, $ino, $mode) = stat(IN);
    die "can't stat $file" unless $ino;

    while(<IN>) {
	if (defined($HaveSharpExcram) && $_ eq $HaveSharpExcram) {
	    $HaveSharpExcram = undef;
	    next;
	}
	if (defined($HavePercentRoundBrace) && $_ eq $HavePercentRoundBrace) {
	    $HavePercentRoundBrace = undef;
	    next;
	}
	print($OUT $_);
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
   PutHeader($i, \@keyword, %$comment) if(defined($comment));
}

GetOptions("config=s" => \$config, "tag=s" => \@tag, "help" => \$help);
@tag = split(/,/, join(',', @tag));

ArgCheck();
%config = ReadConf($config);

if(@tag) {
    foreach $t (@tag) {
	my($c) = $config{$t};
        push(@keyword, map {$_->{'keyword'} } @$c); 
    }
} else {
    foreach $t (keys %config) {
	my($c) = $config{$t};
        push(@keyword, map {$_->{'keyword'} } @$c); 
    }
}

find({wanted => \&wanted}, @ARGV);
exit(0);
