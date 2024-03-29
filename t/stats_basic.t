use strict;
use warnings;
use Test::More;

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

is( tapprox( $a->stdv, 1.4142135623731 ), 1, "standard deviation of $a");
is( tapprox( $a->stdv_unbiased, 1.58113883008419 ), 1, "unbiased standard deviation of $a");
is( tapprox( $a->var, 2 ), 1, "variance of $a");
is( tapprox( $a->var_unbiased, 2.5 ), 1, "unbiased variance of $a");
is( tapprox( $a->se, 0.707106781186548 ), 1, "standard error of $a");
is( tapprox( $a->ss, 10 ), 1, "sum of squared deviations from the mean of $a");
is( tapprox( $a->skew, 0 ), 1, "sample skewness of $a");
is( tapprox( $a->skew_unbiased, 0 ), 1, "unbiased sample skewness of $a");
is( tapprox( $a->kurt, -1.3 ), 1, "sample kurtosis of $a");
is( tapprox( $a->kurt_unbiased, -1.2 ), 1, "unbiased sample kurtosis of $a");

{
  ok(tapprox($_->ss, (($_ - $_->avg)**2)->sum), "ss for $_") for
    pdl('[1 1 1 1 2 3 4 4 4 4 4 4]'),
    pdl('[1 2 2 2 3 3 3 3 4 4 5 5]'),
    pdl('[1 1 1 2 2 3 3 4 4 5 5 5]');
}

my $a_bad = sequence 6;
$a_bad->setbadat(-1);

is( tapprox( $a_bad->stdv, 1.4142135623731 ), 1, "standard deviation of $a_bad");
is( tapprox( $a_bad->stdv_unbiased, 1.58113883008419 ), 1, "unbiased standard deviation of $a_bad");
is( tapprox( $a_bad->var, 2 ), 1, "variance of $a_bad");
is( tapprox( $a_bad->var_unbiased, 2.5 ), 1, "unbiased variance of $a_bad");
is( tapprox( $a_bad->se, 0.707106781186548 ), 1, "standard error of $a_bad");
is( tapprox( $a_bad->ss, 10 ), 1, "sum of squared deviations from the mean of $a_bad");
is( tapprox( $a_bad->skew, 0 ), 1, "sample skewness of $a_bad");
is( tapprox( $a_bad->skew_unbiased, 0 ), 1, "unbiased sample skewness of $a_bad");
is( tapprox( $a_bad->kurt, -1.3 ), 1, "sample kurtosis of $a_bad");
is( tapprox( $a_bad->kurt_unbiased, -1.2 ), 1, "unbiased sample kurtosis of $a_bad");

my $b = sequence 5;
$b %= 2;
$b = qsort $b;

is( tapprox( $a->cov($b), 0.6 ), 1, "sample covariance of $a and $b" );
is( tapprox( $a->corr($b), 0.866025403784439 ), 1, "Pearson correlation coefficient of $a and $b");
is( tapprox( $a->n_pair($b), 5 ), 1, "Number of good pairs between $a and $b");
is( tapprox( $a->corr($b)->t_corr( 5 ), 3 ), 1, "t significance test of Pearson correlation coefficient of $a and $b");
is( tapprox( $a->corr_dev($b), 0.903696114115064 ), 1, "correlation calculated from dev_m values of $a and $b");

my $b_bad = sequence 6;
$b_bad = qsort( $b_bad % 2 );
$b_bad->setbadat(0);

is( tapprox( $a_bad->cov($b_bad), 0.5 ), 1, "sample covariance with bad data of $a_bad and $b_bad");
is( tapprox( $a_bad->corr($b_bad), 0.894427190999916 ), 1, "Pearson correlation coefficient with bad data of $a_bad and $b_bad");
is( tapprox( $a_bad->n_pair($b_bad), 4 ), 1, "Number of good pairs between $a_bad and $b_bad with bad values taken into account");
is( tapprox( $a_bad->corr($b_bad)->t_corr( 4 ), 2.82842712474619 ), 1, "t signifiance test of Pearson correlation coefficient with bad data of $a_bad and $b_bad");
is( tapprox( $a_bad->corr_dev($b_bad), 0.903696114115064 ), 1, "correlation calculated from dev_m values with bad data of $a_bad and $b_bad");

my ($t, $df) = $a->t_test($b);
is( tapprox( $t, 2.1380899352994 ), 1, "t-test between $a and $b - 't' output");
is( tapprox( $df, 8 ), 1, "t-test between $a and $b - 'df' output");

($t, $df) = $a->t_test_nev($b);
is( tapprox( $t, 2.1380899352994 ), 1, "t-test with non-equal variance between $a and $b - 't' output");
is( tapprox( $df, 4.94637223974763 ), 1, "t-test with non-equal variance between $a and $b - 'df' output");

($t, $df) = $a->t_test_paired($b);
is( tapprox( $t, 3.13785816221094 ), 1, "paired sample t-test between $a and $b - 't' output");
is( tapprox( $df, 4 ), 1, "paired sample t-test between $a and $b - 'df' output");

($t, $df) = $a_bad->t_test($b_bad);
is( tapprox( $t, 1.87082869338697 ), 1, "t-test with bad values between $a_bad and $b_bad - 't' output");
is( tapprox( $df, 8 ), 1, "t-test with bad values between $a_bad and $b_bad - 'd' output");

($t, $df) = $a_bad->t_test_nev($b_bad);
is( tapprox( $t, 1.87082869338697 ), 1, "t-test with non-equal variance with bad values between $a_bad and $b_bad - 't' output");
is( tapprox( $df, 4.94637223974763 ), 1, "t-test with non-equal variance with bad values between $a_bad and $b_bad - 'df' output");

($t, $df) = $a_bad->t_test_paired($b_bad);
is( tapprox( $t, 4.89897948556636 ), 1, "paired sample t-test with bad values between $a_bad and $b_bad - 't' output");
is( tapprox( $df, 3 ), 1, "paired sample t-test with bad values between $a_bad and $b_bad - 'df' output");

{
  my ($data, $idv, $ido) = rtable(\*DATA, {V=>0});
  is( tapprox( sum(pdl($data->dims) - pdl(14, 5)), 0 ), 1, 'rtable data dim' );
  is( tapprox( $data->sum / $data->nbad, 1.70731707317073 ), 1, 'rtable bad elem' );
}

{
  my $a = random 10, 3;
  is( tapprox( sum($a->cov_table - $a->cov($a->dummy(1))), 0 ), 1, 'cov_table' );

  $a->setbadat(4,0);
  is( tapprox( sum($a->cov_table - $a->cov($a->dummy(1))), 0 ), 1, 'cov_table bad val' );
}

{
  my $a = random 10, 3;
  is( tapprox( sum(abs($a->corr_table - $a->corr($a->dummy(1)))), 0 ), 1, "Square Pearson correlation table");

  $a->setbadat(4,0);
  is( tapprox( sum(abs($a->corr_table - $a->corr($a->dummy(1)))), 0 ), 1, "Square Pearson correlation table with bad data");
}

{
  my $a = pdl([0,1,2,3,4], [0,0,0,0,0]);
  $a = $a->setvaltobad(0);
  is( $a->stdv->nbad, 1, "Bad value input to stdv makes the stdv itself bad");
}

SKIP: {
  eval { require PDL::Core; require PDL::GSL::CDF; };
  skip 'no PDL::GSL::CDF', 1 if $@;
  my $x = pdl(1, 2);
  my $n = pdl(2, 10);
  my $p = .5;

  my $a = pdl qw[ 0.75  0.9892578125 ];

  is (tapprox( sum(abs(binomial_test( $x,$n,$p ) - $a)) ,0), 1, 'binomial_test');
}

{
    my $a = sequence 10, 2;
    my $factor = sequence(10) > 4;
    my $ans = pdl( [[0..4], [10..14]], [[5..9], [15..19]] );

    my ($a_, $l) = $a->group_by($factor);
    is( tapprox( sum(abs($a_ - $ans)), 0 ), 1, 'group_by single factor equal n' );
    is_deeply( $l, [0, 1], 'group_by single factor label');

    $a = sequence 10,2;
    $factor = qsort sequence(10) % 3;
    $ans = pdl( [1.5, 11.5], [5, 15], [8, 18] );

    is( tapprox( sum(abs($a->group_by($factor)->average - $ans)), 0 ), 1, 'group_by single factor unequal n' );

    $a = sequence 10;
    my @factors = ( [qw( a a a a b b b b b b )], [qw(0 1 0 1 0 1 0 1 0 1)] );
    $ans = pdl(
[
 [0,2,-1],
 [1,3,-1],
],
[
 [4,6,8],
 [5,7,9],
]
    );
    $ans->badflag(1);
    $ans = $ans->setvaltobad(-1);

    ($a_, $l) = $a->group_by( @factors );
    is(tapprox(sum(abs($a_ - $ans)), 0), 1, 'group_by multiple factors') or diag($a_, $ans);
    is_deeply($l, [[qw(a_0 a_1)], [qw( b_0 b_1 )]], 'group_by multiple factors label');
}


{
    my @a = qw(a a b b c c);
    my $a = PDL::Stats::Basic::_array_to_pdl( \@a );
    my $ans = pdl( 0,0,1,1,2,2 );
    is( tapprox( sum(abs($a - $ans)), 0 ), 1, '_array_to_pdl' );

    $a[-1] = undef;
    my $a_bad = PDL::Stats::Basic::_array_to_pdl( \@a );
    my $ans_bad = pdl( 0,0,1,1,2,2 );
    $ans_bad = $ans_bad->setbadat(-1);

    like( $a_bad(-1)->isbad(), qr/1/, '_array_to_pdl with missing value undef' );
    is( tapprox( sum(abs($a_bad - $ans_bad)), 0 ), 1, '_array_to_pdl with missing value undef correctly coded' );

    $a[-1] = 'BAD';
    $a_bad = PDL::Stats::Basic::_array_to_pdl( \@a );

    like( $a_bad(-1)->isbad(), qr/1/, '_array_to_pdl with missing value BAD' );
    is( tapprox( sum(abs($a_bad - $ans_bad)), 0 ), 1, '_array_to_pdl with missing value BAD correctly coded' );
}

done_testing();

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
