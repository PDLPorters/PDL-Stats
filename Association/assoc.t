#!/usr/bin/perl 

use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 3;
    use_ok( 'PDL::Stats::Association' );
}

use PDL::LiteF;
use PDL::NiceSlice;

sub tapprox {
  my($a,$b, $eps) = @_;
  $eps ||= 1e-6;
  my $diff = abs($a-$b);
  ref $diff eq 'PDL' and $diff = $diff->sum;
  return $diff < $eps;
}

{
  my $ab = pdl(qw( 1 1 .3 .1 .3 .3 ))->reshape(3, 2);
  $ab /= 10;
  my $a = pdl ( .5, .5, .2 );
  my $b = pdl ( .4, .1 );
  my $pmi = $ab->pmi( $a, $b );
  my $pmi_ans = pdl( qw(-0.30103 -0.30103 -0.42596873 -0.69897 -0.22184875 0.17609126) )->reshape(3,2);

  is( tapprox( $pmi, $pmi_ans ), 1, 'pmi' );
}

{
  my $a = pdl( qw(1 0 5 0 4 8 5 5) )->reshape(4,2);
  my $w = $a->tf_idf( $a->sumover );
  my $w_ans = pdl( qw( 0 0 0 0 0 0.10946545 0 0.068415908 ) )->reshape(4,2);

  is( tapprox( $w, $w_ans ), 1, 'tf_idf' );
}
