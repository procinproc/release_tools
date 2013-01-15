# $AICS_copyright:$
# $AICS_Release:$
use ExtUtils::MakeMaker;
$perl_version = ($] >= 5.006)? sprintf("%vd", $^V): sprintf("%.3f", $]);
WriteMakefile(
    'INSTALLMAN1DIR' => 'none',
    'INSTALLMAN3DIR' => 'none',
    'NAME' => 'Release',
    'VERSION' => '0.1',
);
