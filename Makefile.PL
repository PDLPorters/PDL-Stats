use strict;
use warnings;
use ExtUtils::MakeMaker 6.54;

WriteMakefile(
    NAME                => 'PDL::Stats',
    AUTHOR              => 'Maggie J. Xiong  <maggiexyz users.sourceforge.net>',
    VERSION_FROM        => 'Stats.pm',
    ABSTRACT_FROM       => 'Stats.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'PDL'        => '2.4.8',
    },
    PREREQ_FATAL        => 1,
    DIR                 => ['Basic', 'Distr', 'GLM', 'Kmeans', 'GSL', 'TS'],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => ['PDL-Stats-*'] },
);
