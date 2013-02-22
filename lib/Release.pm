# $RIKEN_Copyright:$
# $Release_tool_version:$
package Release;
use Exporter 'import';
use Getopt::Long;
use Data::Dumper;
use strict;
use warnings;
use vars qw($VERSION %comment @ISA @EXPORT @EXPORT_OK @config @tag $help %keytable %contents);

@ISA = qw(Exporter);
@EXPORT = qw(GetConfKeywords GetConfContents FileToComment);
@EXPORT_OK = qw(GetConfKeywords GetConfContents FileToComment);
$VERSION = 0.2;

%keytable = ();
sub ReadConf {
    my (@file) = @_;
    my ($file, $tag, $keyword, $contents);
    foreach $file (@file) {
	if(!open(FH, "<$file")) {
	    print "cannot open config file $file\n";
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
    print(STDOUT "\t$0 -config config_file [-tag tag] files ...\n");
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

# hqandle common argument
@config = split(/:/, $ENV{"RELEASE_CONF"}) if (defined($ENV{"RELEASE_CONF"}));
GetOptions("config=s" => \@config, "tag=s" => \@tag, "help" => \$help);
@config = split(/:/, join(':', @config));
@tag = split(/,/, join(',', @tag));

ArgCheck();
ReadConf(@config);

1;
