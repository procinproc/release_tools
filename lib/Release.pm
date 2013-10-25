# $RIKEN_copyright: Copyright 2013 RIKEN All rights reserved.$
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
# $RELEASE_TOOL_VERSION: 0.31$
# Written by Toyohisa Kameyama (kameyama@riken.jp)
package Release;
use Exporter 'import';
use Getopt::Long;
use Data::Dumper;
use strict;
use warnings;
use vars qw($VERSION %comment @ISA @EXPORT @EXPORT_OK @config @tag $help %keytable %contents @path $year);

@ISA = qw(Exporter);
@EXPORT = qw(GetConfKeywords GetConfContents FileToComment addyear);
@EXPORT_OK = qw(GetConfKeywords GetConfContents FileToComment addyear);
$VERSION = 0.2;

%keytable = ();
sub ReadConf {
    my (@file) = @_;
    my ($f, $file, $tag, $keyword, $contents, $path);
    foreach $file (@file) {
	foreach $path (@path) {
	    $f = "$path/$file";
	    last if(-e $f);
	    $f = "$path/$file.conf";
	    last if(-e $f);
	}
	if (! -e $f) {
	    print "cannot find config file $f\n";
	    next;
	}
	if(!open(FH, "<$f")) {
	    print "cannot open config file $f\n";
	    next;
	}
	while(<FH>) {
	    next if (/^#/);
	    ($tag, $keyword, $contents) = split(/\s/,$_, 3);
	    chomp($contents);
	    while ($contents =~ /\\$/) {
		$contents =~ s/\\$/\n/;
		$contents .= <FH>;
		chomp($contents);
	    }
	    $keytable{$tag} = [] if (!exists($keytable{$tag}));
	    my($kc) = $keytable{$tag};
	    my(@kc) = @$kc;
	    push(@kc, {"keyword" => $keyword, "contents" => $contents});
	    $keytable{$tag} = \@kc;
	}
	close(FH);
    }
    return %keytable;
}

sub GetConfKeywords {
    my($tag, @key);
    if (@tag) {
        foreach $tag (@tag) {
	    if(defined($keytable{$tag})) {
	        my($c) = $keytable{$tag};
		my($k);
		foreach $k (@$c) {
		    push(@key, $k->{'keyword'});
		    $contents{$k->{'keyword'}} = $k->{'contents'};
		}
	    }
	}
	return @key;
    } else {
        foreach $tag (keys %keytable) {
	    my($c) = $keytable{$tag};
	    my($k);
	    foreach $k (@$c) {
		push(@key, $k->{'keyword'});
		$contents{$k->{'keyword'}} = $k->{'contents'};
	    }
	}
	return @key;
       return keys %keytable;
    }
}

sub GetConfContents {
   my ($key) = @_;
   return $contents{$key};
}

# comment description
# $comment{LANG}->start  comment start line
# $comment{LANG}->cont   comment continue line
# $comment{LANG}->end    comment end line
%comment = (
    "c" => {'start' => '/* ',
        'cont' => ' * ',
	'end' => ' */'},
    "shell" => {'start' => '# ',
        'cont' => '# ',
	'end' => '# '},
    "imake" => {'start' => 'XCOMM ',
        'cont' => 'XCOMM ',
	'end' => 'XCOMM '},
    "lisp" => {'start' => '; ',
        'cont' => '; ',
	'end' => '; '},
    "Verilog" => {'start' => '// ',
        'cont' => '// ',
	'end' => '// '},
    "as" => {'start' => '/* ',
        'cont' => ' * ',
	'end' => ' */'},
    "java" => {'start' => '/* ',
        'cont' => ' * ',
	'end' => ' */'},
    "html" => {'start' => '<!-- ',
        'cont' => '    ',
	'end' => ' -->'},
    "f77" => {'start' => 'c     ',
        'cont' => 'c    ',
	'end' => 'c      '},
    "f90" => {'start' => '! ',
        'cont' => '! ',
	'end' => '! '},
);       

sub GetCommentStyle {
    my($mode) = @_;

    return $comment{$mode} if(defined($comment{$mode}));
    return undef;
}

sub GetFileName {
    my($name) = @_;
    my(@list) = split(/\//, $name);
    return pop(@list);
}


sub GetDirName {
    my($name) = @_;
    my(@list) = split(/\//, $name);
    pop(@list);
    return join('/', @list);
}


sub GetTmpName {
    my($file) = @_;
    return GetDirName($file) . ".~###" . &GetFileName($file) . ".$$";
}

sub GetSuffix {
    my($file) = GetFileName(@_);
    my($suffix) = $file =~ /(\.[^.]*)$/;
    return $suffix;
}

sub GetPrefix {
    my($file) = &GetFileName(@_);
    $file =~ s/\.[^.]*$//;
    return $file;
}

sub FileToComment {
    my($file) = @_;
    my($sufix) = GetSuffix($file);
    my($prfix) = GetPrefix($file);

    # for Makefile
    if ($prfix =~ /[Mm]akefile/) {
	if ($prfix !~ /^Imakefile$/) {
	    return GetCommentStyle("shell");
	} else {
	    return GetCommentStyle("imake");
	}
    }

    if (defined($sufix)) {
# for C
	if ($sufix eq ".c" || $sufix eq ".C" || $sufix eq ".h" ||
		$sufix eq ".cc" || $sufix eq ".l" || $sufix eq ".y") {
	    return GetCommentStyle("c");
	}

# for perl and tcl
	if ($sufix eq ".pl" || $sufix eq ".tcl" || $sufix eq ".pm") {
	    return GetCommentStyle("shell");
	}

# for Verilog
	if ($sufix eq ".v" || $sufix eq ".V") {
	    return GetCommentStyle("verilog");
	}

# for Assembler
	if ($sufix eq ".s" || $sufix eq ".as") {
	    return GetCommentStyle("as");
	}

# for HTML
	if ($sufix eq ".html" || $sufix eq ".htm") {
	    return GetCommentStyle("html");
	}

# for Java
	if ($sufix eq ".java") {
	    return GetCommentStyle("java");
	}
	if ($sufix eq ".f" || $sufix eq ".F") {
	    return GetCommentStyle("f77");
	}
	if ($sufix eq ".f90" || $sufix eq ".F90") {
	    return GetCommentStyle("f90");
	}
    }

# not determin language only filename... read content of the file
    my($header) = undef;
    my($first) = undef;

    open(IN, "<$file") || die "can't open $file.";
    while(<IN>) {
	next if /^$/;
	chomp;
	$header = $_;
	last;
    }
    close(IN);

    return undef if (!defined($header));
    if ( $header =~ /^#\s*!/ ) {
	$header =~ s/^#\s*!\s*//;
	my($exec) = GetFileName($header);
#	print "debug: exec = $exec\n";
	if ( $exec =~ /.*sh$/ || $exec eq "perl" || $exec eq "wish") {
	    return GetCommentStyle("shell");
	}
    }

    if ( $header =~ /\/\*.*$/ ) {
	return GetCommentStyle("c");
    }

    if ( $header =~ /^[\;]+.*$/ ) {
	return GetCommentStyle("lisp");
    }

    return undef;
}

sub Usage {
    print(STDOUT "usage:\n");
    print(STDOUT "\t$0 -help\n");
    print(STDOUT "\t\tor\n");
    print(STDOUT "\t$0 -config config_file,... [-tag tag,...] [-year year]".
        " files ...\n");
}

sub ArgCheck {
    if ($help) {
	Usage();
	exit(0);
    }
    if (!@ARGV) {
	ErrorExit(1, "No files are specified.");
    }
}
   
sub ErrorExit {
    my($stat, $mes) = @_;
    print(STDERR "Error: $mes\n");
    Usage();
    exit($stat);
}

sub addyear {
    my($ystr) = @_;
    return $year if(!defined($ystr));
    my(@y) = split(/\s*,\s*/, $ystr);
    my($y, $y1, $y2, %y, @yret, $yret, $ydelim, $lasty);
    push(@yret, $year);
    foreach $y (@y) {
        if (($y1, $y2) = $y =~ /^(\d+)\s*-\s*(\d+)$/) {
	    my($y3);
	    if ($y1 < $y2) {
		for($y3 = $y1; $y3 <= $y2; $y3++) {
		     push(@yret, $y3);
		}
	    } else {
		for($y3 = $y2; $y3 <= $y1; $y3++) {
		     push(@yret, $y3);
		}
	    }
	} elsif ($y =~ /^\d+$/) {
	     push(@yret, $y);
	} else {
	    print "Parse error $y, ignore\n";
	}
    }
    $lasty = -1;
    $ydelim = "";
    foreach $y (sort {$a <=> $b} @yret) {
	next if($lasty == $y);
        if($lasty + 1 < $y) {
	    $yret .= $ydelim. $lasty, $ydelim = "," if($ydelim eq "-");
	    $yret .= $ydelim. $y;
	    $ydelim = ",";
	} else {
	    $ydelim = "-";
	}
	$lasty = $y;
    }
    $yret .= $ydelim . $lasty if ($ydelim eq "-");
    return $yret;

}

# hqandle common argument
@path=(".", "@confpath@");
$year = (localtime())[5] + 1900;
@path = split(/:/, $ENV{"RELTOOL_PATH"}) if (defined($ENV{"RELTOOL_PATH"}));
@config = split(/,/, $ENV{"RELTOOL_CONF"}) if (defined($ENV{"RELTOOL_CONF"}));
GetOptions("config=s" => \@config, "tag=s" => \@tag, "help" => \$help,
    "year=s" => \$year);
@config = split(/,/, join(',', @config));
@tag = split(/,/, join(',', @tag));

ArgCheck();
ReadConf(@config);

1;
__END__
=pod
=head1 name

Release - The library to prepare release tool

=head1 SYNOPSIS

    use Relrease;
    @keyword = GetConfKeyword();
    $contents = GetConfContents($keyword);
    $comment = FileToComment($filename);

=head1 DESCRIPTION

Release module is set of the function to insert or expand keyword to
release source files.
The module parse environment variables, command line argument and read
config files.

=over

=item GetConfKeyword

Get keywords list.

=item GetConfContents($keyword)

Get contents of the keyword.

=item FileToComment($filename)

Get Comment information of the filename.
The return value is reference of the hash:
=over
=item $comment->{'start'}
The start of comment.
=item $comment->{'cont'}
The continue line of comment.
=item $comment->{'end'}
The end of comment.
=back
=back
=cut
