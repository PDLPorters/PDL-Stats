#!/usr/bin/perl 

use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 47;
}

use PDL::LiteF;
use PDL::NiceSlice;
use PDL::Stats::Basic;

sub tapprox {
  my($a,$b, $eps) = @_;
  $eps ||= 1e-6;
  my $diff = abs($a-$b);
    # use max to make it perl scalar
  ref $diff eq 'PDL' and $diff = $diff->max;
  return $diff < $eps;
}

my $a = sequence 5;

  # 1-10
is( tapprox( $a->stdv, 1.4142135623731 ), 1, );
is( tapprox( $a->stdv_unbiased, 1.58113883008419 ), 1 );
is( tapprox( $a->var, 2 ), 1 );
is( tapprox( $a->var_unbiased, 2.5 ), 1 );
is( tapprox( $a->se, 0.707106781186548 ), 1 );
is( tapprox( $a->ss, 10 ), 1 );
is( tapprox( $a->skew, 0 ), 1 );
is( tapprox( $a->skew_unbiased, 0 ), 1 );
is( tapprox( $a->kurt, -1.3 ), 1 );
is( tapprox( $a->kurt_unbiased, -1.2 ), 1 );

my $a_bad = sequence 6;
$a_bad->setbadat(-1);

  # 11-20
is( tapprox( $a_bad->stdv, 1.4142135623731 ), 1, );
is( tapprox( $a_bad->stdv_unbiased, 1.58113883008419 ), 1 );
is( tapprox( $a_bad->var, 2 ), 1 );
is( tapprox( $a_bad->var_unbiased, 2.5 ), 1 );
is( tapprox( $a_bad->se, 0.707106781186548 ), 1 );
is( tapprox( $a_bad->ss, 10 ), 1 );
is( tapprox( $a_bad->skew, 0 ), 1 );
is( tapprox( $a_bad->skew_unbiased, 0 ), 1 );
is( tapprox( $a_bad->kurt, -1.3 ), 1 );
is( tapprox( $a_bad->kurt_unbiased, -1.2 ), 1 );

my $b = sequence 5;
$b %= 2;
$b = qsort $b;

  # 21-25
is( tapprox( $a->cov($b), 0.6 ), 1 );
is( tapprox( $a->corr($b), 0.866025403784439 ), 1 );
is( tapprox( $a->n_pair($b), 5 ), 1 );
is( tapprox( $a->corr($b)->t_corr( 5 ), 3 ), 1 );
is( tapprox( $a->corr_dev($b), 0.903696114115064 ), 1 );

my $b_bad = sequence 6;
$b_bad = qsort( $b_bad % 2 );
$b_bad->setbadat(0);

  # 26-30
is( tapprox( $a_bad->cov($b_bad), 0.5 ), 1 );
is( tapprox( $a_bad->corr($b_bad), 0.894427190999916 ), 1 );
is( tapprox( $a_bad->n_pair($b_bad), 4 ), 1 );
is( tapprox( $a_bad->corr($b_bad)->t_corr( 4 ), 2.82842712474619 ), 1 );
is( tapprox( $a_bad->corr_dev($b_bad), 0.903696114115064 ), 1 );

  # 31-36
my ($t, $df) = $a->t_test($b);
is( tapprox( $t, 2.1380899352994 ), 1 );
is( tapprox( $df, 8 ), 1 );

($t, $df) = $a->t_test_nev($b);
is( tapprox( $t, 2.1380899352994 ), 1 );
is( tapprox( $df, 4.94637223974763 ), 1 );

($t, $df) = $a->t_test_paired($b);
is( tapprox( $t, 3.13785816221094 ), 1 );
is( tapprox( $df, 4 ), 1 );

  # 37-42
($t, $df) = $a_bad->t_test($b_bad);
is( tapprox( $t, 1.87082869338697 ), 1 );
is( tapprox( $df, 8 ), 1 );

($t, $df) = $a_bad->t_test_nev($b_bad);
is( tapprox( $t, 1.87082869338697 ), 1 );
is( tapprox( $df, 4.94637223974763 ), 1 );

($t, $df) = $a_bad->t_test_paired($b_bad);
is( tapprox( $t, 4.89897948556636 ), 1 );
is( tapprox( $df, 3 ), 1 );

  # 43-44
{
  my ($data, $idv, $ido) = rtable(\*DATA, {V=>0});
  is( tapprox( sum(pdl($data->dims) - pdl(14, 5)), 0 ), 1, 'rtable data dim' );
  is( tapprox( $data->sum / $data->nbad, 1.70731707317073 ), 1, 'rtable bad elem' );
}

  # 45-46
{
  my $a = random 10, 3;
  is( tapprox( sum($a->corr_table - $a->corr($a->dummy(1))), 0 ), 1 );

  $a->setbadat(4,0);
  is( tapprox( sum($a->corr_table - $a->corr($a->dummy(1))), 0 ), 1 );
}
  # 47
{
  my $a = sequence 5, 2;
  $a( ,1) .= 0;
  $a = $a->setvaltobad(0);
  is( $a->stdv->nbad, 1 );
}

__DATA__
999	90	91	92	93	94	
70	5	7	-999	-999	-999	
711	trying
71	-999	3	-999	-999	0	
72	2	7	-999	-999	-999	
73	-999	0	-999	-999	2	
74	5	-999	1	0	-999	
75	-999	0	-999	-999	0	
76	9	8	1	5	-999	
77	4	-999	-999	-999	-999	
78	-999	0	-999	-999	0	
79	-999	3	-999	-999	0	
80	-999	0	-999	-999	2	
81	5	-999	1	0	-999	
82	-999	0	-999	-999	0	
