use strict;
use warnings;
use ExtUtils::MakeMaker;

if ($] > 5.014000 and $] < 5.015009) {
    warn "Perl version bewteen 5.14.0 and 5.15.8 detected. Sheepishly bailing out of installation because of perl and PDL :lvalue subroutine issue. For more information, please see perl bug ticket #107366 https://rt.perl.org/rt3//Public/Bug/Display.html?id=107366\n";
    exit;
}


WriteMakefile(
    NAME                => 'PDL::Stats',
    AUTHOR              => 'Maggie J. Xiong  <maggiexyz users.sourceforge.net>',
    VERSION_FROM        => 'Stats.pm',
    ABSTRACT_FROM       => 'Stats.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PREREQ_PM => {
        'Test::More' => 0,
        'PDL'        => '2.4.4',
    },
    PREREQ_FATAL        => 0,
    DIR                 => ['Basic', 'Distr', 'GLM', 'Kmeans', 'GSL', 'TS'],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => ['PDL-Stats-*'] },
);

sub MY::postamble {
    my $text =
'
update_doc ::
	@echo "Updating PDL documentation database ..."
	@$(PERL) add_doc.pl

';

    return $text;
}
