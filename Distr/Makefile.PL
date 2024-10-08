use PDL::Core::Dev;
use ExtUtils::MakeMaker;

$package = ["distr.pd",Distr,PDL::Stats::Distr,undef,1];
%hash = pdlpp_stdargs($package);

chomp( my $libgsl = `gsl-config --libs` );
chomp( my $cflags = `gsl-config --cflags` );

if ($libgsl) {
  unshift @{ $hash{'LIBS'} }, $libgsl;
  $hash{'INC'} .= " $cflags";
  WriteMakefile( %hash, NO_MYMETA => 1 );
  sub MY::postamble {pdlpp_postamble($package)};
}
else {
  my $msg = "no GSL lib, skip $package->[-1]";
  warn $msg . "\n";
  write_dummy_make( $msg );
}
