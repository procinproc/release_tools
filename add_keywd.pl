#!/usr/bin/perl



#
# $Id: addrcsheader,v 1.3 2007/01/25 09:19:00 kameyama Exp $
#

use Getopt::Long;
use File::Find;


%C_Comment = (
	      'start', '/* ',
	      'cont',  ' * ',
	      'end',   ' */',
	      );

%Shell_Comment = (
		  'start', '# ',
		  'cont',  '# ',
		  'end',   '# ',
		  );

%Imake_Comment = (
		  'start', 'XCOMM ',
		  'cont',  'XCOMM ',
		  'end',   'XCOMM ',
		  );

%Lisp_Comment = (
		  'start', '; ',
		  'cont',  '; ',
		  'end',   '; ',
		  );

%Verilog_Comment = (
	      'start', '// ',
	      'cont',  '// ',
	      'end',   '// ',
	      );

%As_Comment = (
	      'start', '/* ',
	      'cont',  ' * ',
	      'end',   ' */',
	      );

%Java_Comment = (
	      'start', '/* ',
	      'cont',  ' * ',
	      'end',   ' */',
	      );

%Html_Comment = (
		 'start', '<!-- ',
		 'cont',  '     ',
		 'end',   '-->  ',
		 );

sub GetFileName {
    local($name) = @_;
    local(@list) = split(/\//, $name);
    return $list[$#list];
}


sub GetDirName {
    local($name) = @_;
    local(@list) = split(/\//, $name);
    $list[$#list] = "";
    return join('/', @list);
}


sub GetTmpName {
    local($file) = @_;
    return &GetDirName($file) . ".~###" . &GetFileName($file) . ".$$";
}

sub GetSuffix {
    local($file) = &GetFileName(@_);
    local(@list) = split(/\./, $file);
    if ( @list == 1 ) {
	return "";
    }
    return "." . $list[$#list];
}


sub GetPrefix {
    local($file) = &GetFileName(@_);
    local(@list) = split(/\./, $file);
    return $list[0];
}


sub GuessFileType {
    local($file) = @_;
    local($sufix) = &GetSuffix($file);
    local($prfix) = &GetPrefix($file);
    local($guess) = "unknown";

    # for Makefile
    if ($prfix =~ /.*[Mm]akefile/) {
	if ($prfix !~ /^Imakefile$/) {
	    $guess = "shell";
	} else {
	    return "imake";
	}
    }

    # for C
    if ($sufix eq ".c" || $sufix eq ".C" || $sufix eq ".h" ||
	$sufix eq ".cc" || $sufix eq ".l" || $sufix eq ".y") {
	$guess = "c";
    }

    # for perl and tcl
    if ($sufix eq ".pl" || $sufix eq ".tcl") {
	$guess = "shell";
    }

    # for Verilog
    if ($sufix eq ".v" || $sufix eq ".V") {
	$guess = "verilog";
    }

    # for Assembler
    if ($sufix eq ".s" || $sufix eq ".as") {
	$guess = "as";
    }

    # for HTML
    if ($sufix eq ".html" || $sufix eq ".htm") {
	$guess = "html";
    }

    # for Java
    if ($sufix eq ".java") {
	$guess = "java";
    }

    # for ocore..
    # if () {};

    if (! ($guess eq "unknown")) {
#	print "debug:It's $guess\n";
	return $guess;
    }


    local($header) = undef;
    local($first) = undef;

    open(IN, "<$file") || die "can't open $file.";
    while(<IN>) {
	local($d0, $d1);
	next if /^\n/;
	chop;
	$header = $_;
	($first, $d0, $d1) = split(/[ \t]+/, $_, 3);
#	print "debug:\t0 $first\n\t1 $d0\n\t2 $d1\n";
	if ( $first eq "" ) {
	    $first = $d0;
	}
	last;
    }
    close(IN);

    if ( $header =~ /^#[ \t]*.*$\!/ ) {
	local($exec) = &GetFileName($header);
#	print "debug: exec = $exec\n";
	if ( $exec =~ /.*sh$/ || $exec eq "perl" || $exec eq "wish") {
	    return "shell";
	}
    }

    if ( $first =~ /\/\*.*$/ ) {
	return "c";
    }

    if ( $first =~ /^[\;]+.*$/ ) {
	return "lisp";
    }

    return $first;
}


sub IsCSource {
    local($file) = @_;
    local($sufix) = &GetSuffix($file);

    if (! (&GuessFileType($file) eq "c")) {
	return 0;
    }
    else {
	if ( !($sufix eq ".h" || $sufix eq ".H") ) {
	    return 1;
	}
    }
}


sub Grep {
    local($expr, $file) = @_;
    open(IN, "<$file");
    local(@lines);
    local(@ret);
    while (<IN>) {
	push(@lines, $_);
    }
    close(IN);
    @ret = grep(/$expr/, @lines);
    return @ret;
}


sub PutHeader {
    local ($file, %com) = @_;
    local ($start) = $com{"start"};
    local ($cont) = $com{"cont"};
    local ($end) = $com{"end"};
    local ($tmpfile) = &GetTmpName($file);
    local ($sufix) = &GetSuffix($file);

    if (! -e $file ) {
	open(NEW, ">$file");
	close(NEW);
    }
    local (@DontAICSRelease) = &Grep('AICS_Release', $file);
    local (@DontAICSCopyright) = &Grep('AICS_Copyright', $file);
    local (@DontRCSID);
    local (@HaveSharpExcram) = &Grep('^[ \t]*#[ \t]*!', $file);
    local (@HavePercentRoundBrace);
    if ($sufix eq ".l" || $sufix eq ".y") {
	@HavePercentRoundBrace = &Grep('^[ \t]*\%[ \t]*\{', $file);
    }
    local ($IsMultilineComment) = ($start ne $cont) ? 1 : 0;
    local ($IsC) = &IsCSource($file);
#    if ($IsC) {
#	@DontRCSID = &Grep('char[ \t]+[*]*[ \t]*rcsid', $file);
#    }
#    else {
#	@DontRCSID = &Grep('\$Id', $file);
#    }

    local($In_comment) = 0;

#    print "debug:@HaveSharpExcram\n";
#    print "debug:@HavePercentRoundBrace\n";
#    print "debug:@DontAICSRelease\n";
#    print "debug:@DontAICSCopyright\n";
#    print "debug:@DontRCSID\n";
#    print "debug:$long\n";


    if (@DontAICSRelease &&
	@DontAICSCopyright &&
	@DontRCSID && !$long) {
	return;
    }
	
    open(OUT, ">$tmpfile") || die "can't open $tmpfile.\n";
    
    if (!$IsC && !$IsMultilineComment) {
	if (@HaveSharpExcram) {
	    print(OUT "@HaveSharpExcram\n");
	}
    }

    if ($sufix eq ".l" || $sufix eq ".y") {
	if (@HavePercentRoundBrace) {
	    print(OUT "@HavePercentRoundBrace\n");
	}
    }

#    if (!@DontRCSID) {
#	if ($IsC) {
#	    print(OUT "static char rcsid[] = \"\$Id\$\";\n");
#	}
#	else {
#	    if ($IsMultilineComment) {
#		print(OUT "$start\n");
#		$In_comment = 1;
#	    }
#	    print(OUT $cont . "\$Id\$\n");
#	}
#    }

    if ($IsMultilineComment && !$In_comment) {
	print(OUT "$start\n");
    }

    if (!@DontAICSRelease) {
	print(OUT $cont . "\$AICS_Release\$\n");
    }

    if (!@DontAICSCopyright) {
	print(OUT $cont . "\$AICS_Copyright\$\n");
    }

    if ($long) {
	print(OUT $cont . "\$RCSfile\$\n");
	print(OUT $cont . "\$Revision\$\n");
	print(OUT $cont . "\$Date\$\n");
	print(OUT $cont . "\$Author\$\n");
#	print(OUT $cont . "\$Log\$\n");
    }

    if ($IsMultilineComment) {
	print(OUT $end . "\n");
    }

    open(IN, "<$file") || die "can't open $file.\n";

    local ($dev, $ino, $mode) = stat(IN);
    die "can't stat $file" unless $ino;

    while(<IN>) {
	if (/^[ \t]*#[ \t]*!.*/ && @HaveSharpExcram) {
	    next;
	}
	if (/^[ \t]*\%[ \t]*\{/ && @HavePercentRoundBrace) {
	    next;
	}
	print(OUT $_);
    }
    close(OUT);
    close(IN);

    rename($tmpfile, $file) || die "can't rename from $tmpfile to $file";
    chmod($mode, $file) || die "can't chmod $file";
}


sub ExpandHeader {
    local ($file, $rel, @CopyString) = @_;
    local ($tmpfile) = &GetTmpName($file);

    local (@DoAICSRelease) = &Grep('AICS_Release', $file);
    local (@DoAICSCopyright) = &Grep('AICS_Copyright', $file);

    if ( !@DoAICSRelease && !@DoAICSCopyright ) {
	return;
    }

    open(OUT, ">$tmpfile") || die "can't open $tmpfile.\n";

    open(IN, "<$file") || die "can't open $file.\n";

    local ($dev, $ino, $mode) = stat(IN);
    die "can't stat $file" unless $ino;

    while(<IN>) {
	local($line);
	if (/^(.*)\$[ \t]*AICS_Copyright[ \t]*([:]*[^\$]*[\$]*.*)$/) {
	    local($pre) = $1;
	    local($post) = $2;
	    local($c);
	    $_ = $pre;
	    s/^([ \t]*.*)//;
	    $c = $1;
	    print(OUT $pre);
	    print(OUT "\$AICS_Copyright:\n");
	    foreach $i (@CopyString) {
                chop $i if ($i =~ /\n$/);
		print(OUT "$c $i\n");
	    }
	    print(OUT "$c \$\n");
	    $_ = $post;
	    if (/^[\$].*/) {
		s/://;
		s/\$//;
		s/^[ \t]*//;
		if (/.+/) {
		    print(OUT "$c $_\n");
		}
		next;
	    } else {
		s/://;
		s/\$//;
		s/^[ \t]*//;
		if (/.+/) {
		    print(OUT "$c $_\n");
		}
	    }
	    $_ = $c;
	    s/\*/\\*/g;
	    $c = $_;
	    while (<IN>) {
		chop;
		if (/^$c[ \t]*[\$][ \t]*$/) {
		    last;
		}
	    }
	    next;
	}
	s/\$[ \t]*AICS_Release[ \t]*[:]*[ \t]*[^\$]*\$/\$AICS_Release: $rel \$/;
	print(OUT "$_");
    }
    close(OUT);
    close(IN);

    rename($tmpfile, $file) || die "can't rename from $tmpfile to $file";
    chmod($mode, $file) || die "can't chmod $file";
}


sub GetFileTypeInteractive {
    local($file, $com) = @_;
    local($ret);
    print(STDOUT "Warrning:\tI can't guess comment leader for $file.\n");
    print(STDOUT "\t\tCan I use '$com' as comment leader ?\n");
    print(STDOUT "\t\tIf OK, hit return. Otherwise input comment leader: ");
    $ret = <STDIN>;
    chop($ret);
    if ( "X$ret" eq "X" ) {
	return $com;
    }
    else {
	return $ret;
    }
}


sub GetCommentStyle {
    local($mode) = @_;
    local(%Comment);

    if ($mode eq "shell") {
	%Comment = %Shell_Comment;
    } elsif ($mode eq "c" || $mode =~ /[\/]*\*[\/]*/ ) {
	%Comment = %C_Comment;
    } elsif ($mode eq "lisp") {
	%Comment = %Lisp_Comment;
    } elsif ($mode eq "imake") {
	%Comment = %Imake_Comment;
    } elsif ($mode eq "verilog") {
	%Comment = %Verilog_Comment;
    } elsif ($mode eq "as") {
	%Comment = %As_Comment;
    } elsif ($mode eq "html") {
	%Comment = %Html_Comment;
    } elsif ($mode eq "java") {
	%Comment = %Java_Comment;
    }
    return %Comment;
}


sub SetCommentStyle {
    local($mode) = @_;
    local(%Comment);

    if ($mode eq "shell") {
	%Comment = %Shell_Comment;
    } elsif ($mode eq "c" || $mode =~ /[\/]*\*[\/]*/ ) {
	%Comment = %C_Comment;
    } elsif ($mode eq "lisp") {
	%Comment = %Lisp_Comment;
    } elsif ($mode eq "imake") {
	%Comment = %Imake_Comment;
    } elsif ($mode eq "verilog") {
	%Comment = %Verilog_Comment;
    } elsif ($mode eq "as") {
	%Comment = %As_Comment;
    } elsif ($mode eq "java") {
	%Comment = %Java_Comment;
    }
    else {
	%Comment = (
		    'start', $mode . " ",
		    'cont',  $mode . " ",
		    'end',   $mode . " ",
		    );
    }
    return %Comment;
}


sub Usage {
    print(STDOUT "usage:\n");
    print(STDOUT "\t$ProgName -help\n");
    print(STDOUT "\t\tor\n");
    if ( $ProgName =~ /^add/ ) {
	print(STDOUT "\t$ProgName [-comment <comment_leader>] files ...\n");
    } else  {
	print(STDOUT "\t$ProgName\t-release <release string>\n\t\t\t\t-copyright <copyright file>\n\t\t\t\tfiles ...\n");
    }
}


sub ErrorExit {
    local($stat, $mes) = @_;
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
    if ( $ProgName !~ /^add/ ) {
	if (!$copy) {
	    &ErrorExit(1, "No copyright file is specified.");
	}
    }
}
   
sub wanted {
   local ($save) = $_;
   local ($i) = $_;

   /^CVS(ROOT)?$/ && ($prune = 1, return);
   return if (-d $_);
   return if (/\.gif$/);
   return if (/\.jpg$/);
   return if (/\.png$/);
   return if (/\.gz$/);
   &process_file($i);
   $_ = $save;
}

sub process_file {
   local($_) = $@;

   if ( -l $_ ) {
	$i = readlink($i);
   }
   if ( $ProgName =~ /^add/ ) {
	if (!$comstr) {
	    $mode = &GuessFileType($i);
	    %Comment = &GetCommentStyle($mode);
	    $start = $Comment{"start"};
	    if ( "X$start" eq "X" ) {
		print "$start\n";
		$mode = &GetFileTypeInteractive($i, $mode);
		%Comment = &SetCommentStyle($mode);
	    }
	}
	&PutHeader($i, %Comment);
   } else {
	&ExpandHeader($i, $rel, @CopyString);
   }
}

$ProgName = &GetFileName($0);
if ( $ProgName =~ /^add/ ) {
    GetOptions("comment=s" => \$comstr, "long" => \$long, "help" => \$help);

    &ArgCheck();
    
    if ($comstr) {
	%Comment = &SetCommentStyle($comstr);
    }
} elsif ( $ProgName !~ /^add/ ) {
    GetOptions("help" => \$help, "release=s" => \$rel,
        "copyright=s" => \$copy);

    &ArgCheck();

    if ($copy) {
	open(IN, "<$copy") || die "can't open $copy.";
	while (<IN>) {
	    push(@CopyString, $_);
	}
	close(IN);
    }
}

find({wanted => \&wanted}, @ARGV);
exit(0);
