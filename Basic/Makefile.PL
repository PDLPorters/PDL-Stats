use ExtUtils::MakeMaker;
use PDL::Core::Dev;
if (defined(&PDL::indx)) {
        print STDERR "*** PDL with 64bit support detected. ***\n*** Please note that PDL::Stats does not currently have 64bit support. ***\n";
}

eval q{
        $package = ["stats_basic.pd",Basic,PDL::Stats::Basic];
        %hash = pdlpp_stdargs($package);

        WriteMakefile( %hash );

        sub MY::postamble {pdlpp_postamble($package)};
};
