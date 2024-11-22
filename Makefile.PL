use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

use Getopt::Long;

my $force;
my $result = GetOptions("force"=>\$force);

if ($] >= 5.015000 and $] < 5.015009 and !$force) {
    warn "Perl version between 5.15.0 and 5.15.8 detected. Sheepishly bailing out of installation because of perl and PDL :lvalue subroutine issue. Use --force with 'perl Makefile.PL' to attemp a build anyways. For more information, please see perl bug ticket #107366 https://rt.perl.org/rt3//Public/Bug/Display.html?id=107366\n";
    exit;
}

my $got_PDL = eval { require PDL::Core::Dev };

WriteMakefile(
    NAME                => 'PDL::Stats',
    AUTHOR              => 'Maggie J. Xiong  <maggiexyz users.sourceforge.net>',
    VERSION_FROM        => 'Stats.pm',
    ABSTRACT_FROM       => 'Stats.pm',
    LICENSE=> 'perl',
    PREREQ_PM => {
        'PDL'  => '2.073', # PDL_IF_BAD
    },
    CONFIGURE_REQUIRES => {
        'PDL'  => '2.073',
    },
    BUILD_REQUIRES => {
        'PDL'  => '2.073',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88', # done_testing
        'Test::PDL' => '0.21',
    },
    $got_PDL ? () : (DIR => []), # just write MYMETA if no PDL
    dist                => { PREOP => 'gsl-config --version && $(PERL) -MPDL::Core::Dev -e pdlpp_mkgen $(DISTVNAME)' },
    clean               => { FILES => ['PDL-Stats-*'] },
    META_MERGE          => {
      "meta-spec" => { version => 2 },
      prereqs => {
        develop => {
          requires => {
            'CPAN::Changes' => 0,
          },
        },
        runtime => {
          recommends => {
            'PDL::Graphics::PGPLOT' => 0,
            'PDL::GSL' => 0,
            'PDL::Slatec' => 0,
          },
        },
      },
      resources => {
        repository => {
          type => 'git',
          url => 'git://github.com/PDLPorters/PDL-Stats',
          web => 'https://github.com/PDLPorters/PDL-Stats',
        },
      },
    },
);

sub MY::postamble {
  my $oneliner = PDL::Core::Dev::_oneliner(qq{exit if \$ENV{DESTDIR}; use PDL::Doc; eval { PDL::Doc::add_module(shift); }});
  qq|\ninstall :: pure_install\n\t$oneliner \$(NAME)\n|;
}
