use strict;
use warnings;
use Test::More;
use PDL::LiteF;
use PDL::NiceSlice;
use PDL::Stats::TS;

sub tapprox {
  my($a,$b, $eps) = @_;
  $eps ||= 1e-6;
  my $diff = abs($a-$b);
    # use max to make it perl scalar
  ref $diff eq 'PDL' and $diff = $diff->max;
  return $diff < $eps;
}

{
  my $a = sequence 10;
  
  is(tapprox( sum($a->acvf(4) - pdl qw(82.5 57.75 34 12.25 -6.5) ), 0 ), 1, "autocovariance on $a");
  is(tapprox( sum($a->acf(4) - pdl qw(1 0.7 0.41212121 0.14848485 -0.078787879) ), 0 ), 1, "autocorrelation on $a");
  is(tapprox( sum($a->filter_ma(2) - pdl qw( 0.6 1.2 2 3 4 5 6 7 7.8 8.4 ) ), 0 ), 1, "filter moving average on $a");
  is(tapprox( sum($a->filter_exp(.8) - pdl qw( 0 0.8 1.76 2.752 3.7504 4.75008   5.750016  6.7500032  7.7500006  8.7500001 ) ), 0 ), 1, "filter with exponential smoothing on $a");
  is(tapprox( $a->acf(5)->portmanteau($a->nelem), 11.1753902662994 ), 1, "portmanteau significance test on $a");

  my $b = sequence(10) + 1;
  $b = lvalue_assign_detour( $b, 7, 9 );
  is( tapprox( $b->mape($a), 0.302619047619048 ), 1, "mean absolute percent error between $a and $b");
  is( tapprox( $b->mae($a), 1.1 ), 1, "mean absolute error between $a and $b");

  $b = $b->setbadat(3);
  is( tapprox( $b->mape($a), 0.308465608465608 ), 1, "mean absolute percent error with bad data between $a and $b");
  is( tapprox( $b->mae($a), 1.11111111111111 ), 1, "mean absolute error with bad data between $a and $b");
}

{
  my $a = sequence(5)->dummy(1,2)->flat->sever;
  is(tapprox( sum($a->dseason(5) - pdl qw( 0.6 1.2 2 2 2 2 2 2 2.8 3.4 )), 0 ), 1, "deseasonalize data on $a with period 5");
  is(tapprox( sum($a->dseason(4) - pdl qw( 0.5 1.125 2 2.375 2.125 1.875 1.625 2 2.875 3.5 )), 0 ), 1, "deseasonalize data on $a with period 4");

  $a = $a->setbadat(4);
  is(tapprox( sum($a->dseason(5) - pdl qw( 0.6 1.2 1.5 1.5 1.5 1.5 1.5 2 2.8 3.4 )), 0 ), 1, "deseasonalize data with bad data on $a with period 5");
  is(tapprox( sum($a->dseason(4) - pdl qw( 0.5 1.125 2  1.8333333 1.5  1.1666667 1.5 2 2.875 3.5 )), 0 ), 1, "deseasonalized data with bad data on $a with period 4");
}

{
  my $a = sequence 4, 2;
  $a = $a->setbadat(2,0);
  $a = $a->setbadat(2,1);
  my $a_ans = pdl( [qw( 0 1 1.75 3)], [qw( 4 5 5.75 7 )], );
  is( tapprox( sum($a->fill_ma(2) - $a_ans ), 0 ), 1, "fill missing data with moving average");
}

{
  my $x = sequence 2;
  my $b = pdl(.8, -.2, .3);
  my $xp = $x->pred_ar($b, 7);
  is( tapprox(sum($xp - pdl(qw[0 1 1.1 0.74 0.492 0.3656 0.31408])),0), 1, "predict autoregressive series");
  my $xp2 = $x->pred_ar($b(0:1), 7, {const=>0});
  $xp2($b->dim(0)-1 : -1) += .3;
  is( tapprox(sum($xp - $xp2),0), 1, "predict autoregressive series with no constant last value");
}

{
  my $a = sequence 10;
  my $b = pdl( qw(0 1 1 1 3 6 7 7 9 10) );
  is( tapprox($a->wmape($b) - 0.177777777777778, 0), 1, "weighted mean absolute percent error between $a and $b");
  $a = $a->setbadat(4);
  is( tapprox($a->wmape($b) - 0.170731707317073, 0), 1, "weighted mean absolute percent error with bad data between $a and $b");
}

{
  my $a = sequence(5)->dummy(1,3)->flat->sever;
  $a = lvalue_assign_detour( $a, 1, 3);
  $a = $a->dummy(1,2)->sever;
  my $ind = sequence($a->dims)->(4,1)->flat;
  $a = lvalue_assign_detour($a, $ind, 0);

  my $ans_m = pdl(
 [         4,         0, 1.6666667,         2,         3],
 [ 2.6666667,         0, 1.6666667,         2,         3],
  );

  my $ans_ms = pdl(
 [         0,         0,0.88888889,         0,         0],
 [ 3.5555556,         0,0.88888889,         0,         0],
  );

  my ($m, $ms) = $a->season_m( 5, {start_position=>1, plot=>0} );

  is( tapprox(sum(abs($m - $ans_m)), 0), 1, 'season_m m' );
  is( tapprox(sum(abs($ms - $ans_ms)), 0), 1, 'season_m ms' );
}

done_testing;

sub lvalue_assign_detour {
    my ($pdl, $index, $new_value) = @_;

    my @arr = list $pdl;
    my @ind = ref($index)? list($index) : $index; 
    $arr[$_] = $new_value
        for (@ind);

    return pdl(\@arr)->reshape($pdl->dims)->sever;
}
