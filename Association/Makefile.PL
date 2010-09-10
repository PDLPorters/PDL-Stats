use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();

$package = ["assoc.pp",Association,PDL::Stats::Association];
%hash = pdlpp_stdargs($package);

WriteMakefile( %hash );

sub MY::postamble {pdlpp_postamble($package)};
