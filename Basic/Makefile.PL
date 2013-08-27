# Stolen from PDL::Graphics::PLplot's Makefile.PL
use ExtUtils::MakeMaker;
eval {
	require PDL::Core::Dev;
	PDL::Core::Dev->import;
};
my $pdl_installed = ($@) ? 0 : 1; # make always == 1 for install from PDL distro.

if (!$pdl_installed) {
	# write dummy makefile if PDL not installed
	WriteMakefile(
		'NAME'		=> 'PDL::Stats::Basic',
		'PREREQ_PM'	=> { 'PDL' => '2.4.4' },
	);
	print STDERR "Wrote dummy Makefile for cpan install\n";
	exit;
} else {
	eval q{
		$package = ["stats_basic.pp",Basic,PDL::Stats::Basic];
		%hash = pdlpp_stdargs($package);

		WriteMakefile( %hash );

		sub MY::postamble {pdlpp_postamble($package)};
	};
}
