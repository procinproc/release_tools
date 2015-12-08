#!/usr/bin/perl

# $RIKEN_copyright: Copyright 2015 RIKEN All rights reserved.$

# Copyright (c) 2001,2000,1999,1998,1997
#       Real World Computing Partnership
# Copyright (C) 2003-2011 PC Cluster Consortium

use lib qw(@PERLLIB@);
use Getopt::Long;
use File::Find;
use File::Temp qw(tempfile);
use Release;
use Data::Dumper;
use strict;
use warnings;
use vars qw($help %config $config @tag @keyword $t $verbose);

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
   PutHeader($i, \@keyword, %$comment) if(defined($comment));
}


GetOptions("verbose" => \$verbose);
@keyword = GetConfKeywords();

find({wanted => \&wanted}, @ARGV);
exit(0);
__END__
=pod
=head1 NAME

add_keyword - Add keyword into source files for release.

=head1 SYNOPSIS

add_keyword [-config configfiles] [-tag tags] file file...

=head1 DESCRIPTION

C(add_keyword) insert specific bkeywords in the files.
The keywords are specifies config files and tags.
The keywords are inserted in the comment.

=head2 options

=over

=item -config configfiles
Specify config files.
If you want to use multiple files, please separate "," to the filenames.
The filename serched to the path to environment variable RELTOOL_PATH.
If the environment variable is not set, search @PERLETC@ and current directory.

If -config options is not specified, add_keyword use environment variable
RELTOOL_COMF.

=item -tag tags.

Specify tag for the keywords.
If you want to use multiple tags, please separate "," to the tag.
If tag is specified, all keyword in the config files are used.

=item file

The file to insert keywords.
You can specifies multiple files.
If you specify directory, all files into the directory is used.

=back

add_keyword inserted keyword only known language by the add_keyword.
If you want to add language, please modify Release module.

=head1 SEE ALSO

expand_keyword(1),
release_config(5).
=cut
