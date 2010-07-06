use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use PDL::Lite;';
if ($@) {
  print STDERR "Please retry after PDL::Lite is properly installed.\n";
  exit 0;
}

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
        'PDL::Lite'  => 2.4.4,    # bad value support turned on by default
    },
    PREREQ_FATAL        => 1,
    DIR                 => ['Basic', 'Distr', 'GLM', 'Kmeans', 'GSL', 'TS'],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => ['PDL-Stats-*'] },
);
