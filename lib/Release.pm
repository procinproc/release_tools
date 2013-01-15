package Release;
use Exporter 'import';
use strict;
use warnings;
use vars qw($VERSION %comment @ISA @EXPORT @EXPORT_OK);

@ISA = qw(Exporter);
@EXPORT = qw(ReadConf FileToComment);
@EXPORT_OK = qw(ReadConf FileToComment);
$VERSION = 0.1;

sub ReadConf {
    my ($file) = @_;
    my ($tag, $keyword, $contents, %keytable);
    open(FH, "<$file") || return undef;
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
    return %keytable;
}


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
	if ($sufix eq ".pl" || $sufix eq ".tcl") {
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

1;
