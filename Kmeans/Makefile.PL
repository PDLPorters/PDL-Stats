   use PDL::Core::Dev;
   use ExtUtils::MakeMaker;
   PDL::Core::Dev->import();
   
   $package = ["kmeans.pp",Kmeans,PDL::Stats::Kmeans];
   %hash = pdlpp_stdargs($package);
   
   WriteMakefile( %hash );
   
   sub MY::postamble {pdlpp_postamble($package)};
