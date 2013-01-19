#!/usr/bin/perl

pp_add_exported( );

pp_addpm({At=>'Top'}, <<'EOD');

use strict;
use warnings;

use Carp;
use PDL::LiteF;

$PDL::onlinedoc->scan(__FILE__) if $PDL::onlinedoc;

eval {
  require PDL::Graphics::PGPLOT::Window;
  PDL::Graphics::PGPLOT::Window->import( 'pgwin' );
};
my $PGPLOT = 1 if !$@;

my $DEV = ($^O =~ /win/i)? '/png' : '/xs';

=head1 NAME

PDL::Stats::Distr -- parameter estimations and probability density functions for distributions.

=head1 DESCRIPTION

Parameter estimate is maximum likelihood estimate when there is closed form estimate, otherwise it is method of moments estimate.

=head1 SYNOPSIS

    use PDL::LiteF;
    use PDL::Stats::Distr;

      # do a frequency (probability) plot with fitted normal curve

    my ($xvals, $hist) = $data->hist;

      # turn frequency into probability
    $hist /= $data->nelem;

      # get maximum likelihood estimates of normal curve parameters
    my ($m, $v) = $data->mle_gaussian();

      # fitted normal curve probabilities
    my $p = $xvals->pdf_gaussian($m, $v);

    use PDL::Graphics::PGPLOT::Window;
    my $win = pgwin( Dev=>"/xs" );

    $win->bin( $hist );
    $win->hold;
    $win->line( $p, {COLOR=>2} );
    $win->close;

Or, play with different distributions with B<plot_distr> :)

    $data->plot_distr( 'gaussian', 'lognormal' );

=cut

EOD

pp_addhdr('
#include <math.h>
#include <gsl/gsl_sf_gamma.h>

');

pp_def('mme_beta',
  Pars      => 'a(n); float+ [o]alpha(); float+ [o]beta()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '
    $GENERIC(alpha) sa, a2, m, v;
    sa = 0; a2 = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
      a2 += pow($a(), 2);
    %}
    m = sa / N;
    v = a2 / N - pow(m, 2);
    $alpha() = m * ( m * (1 - m) / v - 1 ); 
    $beta()  = (1 - m) * ( m * (1 - m) / v - 1 );
  ',
  BadCode   => '
    $GENERIC(alpha) sa, a2, m, v;
    sa = 0; a2 = 0;
    long N = 0;
    loop (n) %{
      if ($ISGOOD( $a() )) {
	sa += $a();
	a2 += pow($a(), 2);
        N ++;
      }
    %}
    if (N) {
      m = sa / N;
      v = a2 / N - pow(m, 2);
      $alpha() = m * ( m * (1 - m) / v - 1 ); 
      $beta()  = (1 - m) * ( m * (1 - m) / v - 1 );
    }
    else {
      $SETBAD(alpha());
      $SETBAD(beta());
    }
  ',
  Doc      => '

=for usage

    my ($a, $b) = $data->mme_beta();

=for ref

beta distribution. pdf: f(x; a,b) = 1/B(a,b) x^(a-1) (1-x)^(b-1)

=cut

  ',

);

pp_def('pdf_beta',
  Pars      => 'x(); a(); b(); float+ [o]p()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '

  if ($x()>=0 && $x()<=1) {
    double B_1 = 1 / gsl_sf_beta( $a(), $b() );
    $p() = B_1 * pow($x(), $a()-1) * pow(1-$x(), $b()-1);
  }
  else {
    barf("x out of range [0,1]");
  }
  ',
  BadCode   => '

if ( $ISBAD($x()) || $ISBAD($a()) || $ISBAD($b()) ) {
  $SETBAD( $p() );
}
else {
  if ($x()>=0 && $x()<=1) {
    double B_1 = 1 / gsl_sf_beta( $a(), $b() );
    $p() = B_1 * pow($x(), $a()-1) * pow(1-$x(), $b()-1);
  }
  else {
    barf("x out of range [0,1]");
  }
}

  ',
  Doc      => '

=for ref

probability density function for beta distribution. x defined on [0,1].

=cut

  ',

);

pp_def('mme_binomial',
  Pars      => 'a(n); int [o]n_(); float+ [o]p()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '
    $GENERIC(p) sa, a2, m, v;
    sa = 0; a2 = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
      a2 += pow($a(), 2);
    %}
    m = sa / N;
    v = a2 / N - pow(m, 2);
    $p()  = 1 - v/m;
    $n_() = m / $p() >= 0? (int) (m / $p() + .5) : (int) (m / $p() - .5);
    $p()  = m / $n_(); 
  ',
  BadCode   => '
    $GENERIC(p) sa, a2, m, v;
    sa = 0; a2 = 0;
    long N = 0;
    loop (n) %{
      if ($ISGOOD( $a() )) {
	sa += $a();
	a2 += pow($a(), 2);
        N ++;
      }
    %}
    if (N) {
      m = sa / N;
      v = a2 / N - pow(m, 2);
      $p()  = 1 - v/m;
      $n_() = m / $p() >= 0? (int) (m / $p() + .5) : (int) (m / $p() - .5);
      $p()  = m / $n_();
    }
    else {
      $SETBAD(n_());
      $SETBAD(p());
    }
  ',
  Doc      => '

=for usage

    my ($n, $p) = $data->mme_binomial;

=for ref

binomial distribution. pmf: f(k; n,p) = (n k) p^k (1-p)^(n-k) for k = 0,1,2..n 

=cut

  ',

);

pp_def('pmf_binomial',
  Pars      => 'ushort x(); ushort n(); p(); float+ [o]out()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '

    $GENERIC(out) bc = gsl_sf_choose($n(), $x());
    $out() = bc * pow($p(), $x()) * pow(1-$p(), $n() - $x());
  ',
  BadCode   => '

if ( $ISBAD($x()) || $ISBAD($n()) || $ISBAD($p()) ) {
  $SETBAD( $out() );
}
else {
  $GENERIC(out) bc = gsl_sf_choose($n(), $x());
  $out() = bc * pow($p(), $x()) * pow(1-$p(), $n() - $x());
}

  ',
  Doc      => '

=for ref

probability mass function for binomial distribution.

=cut

  ',

);

pp_def('mle_exp',
  Pars      => 'a(n); float+ [o]l()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '
    $GENERIC(l) sa = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
    %}
    $l() = N / sa;
  ',
  BadCode   => '
    $GENERIC(l) sa = 0;
    long N = 0;
    loop (n) %{
      if ($ISGOOD( $a() )) {
	sa += $a();
        N ++;
      }
    %}
    if (sa > 0) {  $l() = N / sa;  }
    else        {  $SETBAD(l());   }
  ',
  Doc      => '

=for usage

    my $lamda = $data->mle_exp;

=for ref

exponential distribution. mle same as method of moments estimate.

=cut

  ',

);

pp_def('pdf_exp',
  Pars      => 'x(); l(); float+ [o]p()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '

  $p() = $l() * exp( -1 * $l() * $x() );

  ',
  BadCode   => '

if ( $ISBAD($x()) || $ISBAD($l()) ) {
  $SETBAD( $p() );
}
else {
  $p() = $l() * exp( -1 * $l() * $x() );
}

  ',
  Doc      => '

=for ref

probability density function for exponential distribution.

=cut

  ',

);

pp_def('mme_gamma',
  Pars      => 'a(n); float+ [o]shape(); float+ [o]scale()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '
    $GENERIC(shape) sa, a2, m, v;
    sa = 0; a2 = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
      a2 += pow($a(), 2);
    %}
    m = sa / N;
    v = a2 / N - pow(m, 2);
    $shape() = pow(m, 2) / v; 
    $scale() = v / m;
  ',
  BadCode   => '
    $GENERIC(shape) sa, a2, m, v;
    sa = 0; a2 = 0;
    long N = 0;
    loop (n) %{
      if ($ISGOOD( $a() )) {
	sa += $a();
	a2 += pow($a(), 2);
        N ++;
      }
    %}
    if (N) {
      m = sa / N;
      v = a2 / N - pow(m, 2);
      $shape() = pow(m, 2) / v; 
      $scale() = v / m;
    }
    else {
      $SETBAD(shape());
      $SETBAD(scale());
    }
  ',
  Doc      => '

=for usage

    my ($shape, $scale) = $data->mme_gamma();

=for ref

two-parameter gamma distribution

=cut

  ',

);

pp_def('pdf_gamma',
  Pars      => 'x(); a(); t(); float+ [o]p()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '

  double g = gsl_sf_gamma( $a() );
  $p() = pow($x(), $a()-1) * exp(-1*$x() / $t()) / (pow($t(), $a()) * g);

  ',
  BadCode   => '

if ( $ISBAD($x()) || $ISBAD($a()) || $ISBAD($t()) ) {
  $SETBAD( $p() );
}
else {
  double g = gsl_sf_gamma( $a() );
  $p() = pow($x(), $a()-1) * exp(-1*$x() / $t()) / (pow($t(), $a()) * g);
}

  ',
  Doc      => '

=for ref

probability density function for two-parameter gamma distribution.

=cut

  ',

);

pp_def('mle_gaussian',
  Pars      => 'a(n); float+ [o]m(); float+ [o]v()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '
    $GENERIC(m) sa, a2;
    sa = 0; a2 = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
      a2 += pow($a(), 2);
    %}
    $m()  = sa / N;
    $v() = a2 / N - pow($m(),2);
  ',
  BadCode   => '
    $GENERIC(m) sa, a2;
    sa = 0; a2 = 0;
    long N = 0;
    loop (n) %{
      if ($ISGOOD( $a() )) {
	sa += $a();
	a2 += pow($a(), 2);
        N ++;
      }
    %}
    if (N) {
      $m()  = sa / N;
      $v() = a2 / N - pow($m(),2);
    }
    else {
      $SETBAD(m());
      $SETBAD(v());
    }
  ',
  Doc      => '

=for usage

    my ($m, $v) = $data->mle_gaussian();

=for ref

gaussian aka normal distribution. same results as $data->average and $data->var. mle same as method of moments estimate.

=cut

  ',

);

pp_def('pdf_gaussian',
  Pars      => 'x(); m(); v(); float+ [o]p()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '

  $p() = 1 / sqrt($v() * 2 * M_PI)
       * exp( -1 * pow($x() - $m(), 2) / (2*$v()) );

  ',
  BadCode   => '

if ( $ISBAD($x()) || $ISBAD($m()) || $ISBAD($v()) ) {
  $SETBAD( $p() );
}
else {
  $p() = 1 / sqrt($v() * 2 * M_PI)
       * exp( -1 * pow($x() - $m(), 2) / (2*$v()) );
}

  ',
  Doc      => '

=for ref

probability density function for gaussian distribution.

=cut

  ',

);

pp_def('mle_geo',
  Pars      => 'a(n); float+ [o]p();',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '
    $GENERIC(p) sa = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
    %}
    $p()  = 1 / (1 + sa/N);
  ',
  BadCode   => '
    $GENERIC(p) sa = 0;
    long N = 0;
    loop (n) %{
      if ($ISGOOD( $a() )) {
	sa += $a();
        N ++;
      }
    %}
    if (N) {  $p()  = 1 / (1 + sa/N);  }
    else   {  $SETBAD(p());  }
  ',
  Doc      => '

=for ref

geometric distribution. mle same as method of moments estimate.

=cut

  ',

);

pp_def('pmf_geo',
  Pars      => 'ushort x(); p(); float+ [o]out()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '

  $out() = pow(1-$p(), $x()) * $p();

  ',
  BadCode   => '

if ( $ISBAD($x()) || $ISBAD($p()) ) {
  $SETBAD( $out() );
}
else {
  $out() = pow(1-$p(), $x()) * $p();
}

  ',
  Doc      => '

=for ref

probability mass function for geometric distribution. x >= 0.

=cut

  ',

);

pp_def('mle_geosh',
  Pars      => 'a(n); float+ [o]p();',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '
    $GENERIC(p) sa = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
    %}
    $p()  = N / sa;
  ',
  BadCode   => '
    $GENERIC(p) sa = 0;
    long N = 0;
    loop (n) %{
      if ($ISGOOD( $a() )) {
	sa += $a();
        N ++;
      }
    %}
    if (sa > 0) { $p()  = N / sa; }
    else        { $SETBAD(p()); }
  ',
  Doc      => '

=for ref

shifted geometric distribution. mle same as method of moments estimate.

=cut

  ',

);

pp_def('pmf_geosh',
  Pars      => 'ushort x(); p(); float+ [o]out()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '
  if ( $x() >= 1 ) {
    $out() = pow(1-$p(), $x()-1) * $p();
  }
  else {
    barf( "x >= 1 please" );
  }

  ',
  BadCode   => '

if ( $ISBAD($x()) || $ISBAD($p()) ) {
  $SETBAD( $out() );
}
else {
  if ( $x() >= 1 ) {
    $out() = pow(1-$p(), $x()-1) * $p();
  }
  else {
    barf( "x >= 1 please" );
  }
}

  ',
  Doc      => '

=for ref

probability mass function for shifted geometric distribution. x >= 1.

=cut

  ',

);

pp_def('mle_lognormal',
  Pars      => 'a(n); float+ [o]m(); float+ [o]v()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '
    $GENERIC(m) sa, a2;
    sa = 0; a2 = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += log($a());
    %}
    $m() = sa / N;
    loop (n) %{
      a2 += pow(log($a()) - $m(), 2);
    %}
    $v() = a2 / N;
  ',
  BadCode   => '
    $GENERIC(m) sa, a2;
    sa = 0; a2 = 0;
    long N = 0;
    loop (n) %{
      if ($ISGOOD( $a() )) {
        sa += log($a());
        N ++;
      }
    %}
    if (N) {
      $m() = sa / N;
      loop (n) %{
        if ($ISGOOD( $a() )) {
          a2 += pow(log($a()) - $m(), 2);
        }
      %}
      $v() = a2 / N;
    }
    else {
      $SETBAD(m());
      $SETBAD(v());
    }
    
  ',
  Doc      => '

=for usage

    my ($m, $v) = $data->mle_lognormal();

=for ref

lognormal distribution. maximum likelihood estimation.

=cut

  ',

);

pp_def('mme_lognormal',
  Pars      => 'a(n); float+ [o]m(); float+ [o]v()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '
    $GENERIC(m) sa, a2;
    sa = 0; a2 = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
      a2 += pow($a(), 2);
    %}
    $m()  = 2 * log(sa / N) - 1/2 * log( a2 / N );
    $v() = log( a2 / N ) - 2 * log( sa / N );
  ',
  BadCode   => '
    $GENERIC(m) sa, a2;
    sa = 0; a2 = 0;
    long N = 0;
    loop (n) %{
      if ($ISGOOD( $a() )) {
	sa += $a();
	a2 += pow($a(), 2);
        N ++;
      }
    %}
    if (N) {
      $m()  = 2 * log(sa / N) - 1/2 * log( a2 / N );
      $v() = log( a2 / N ) - 2 * log( sa / N );
    }
    else {
      $SETBAD(m());
      $SETBAD(v());
    }
  ',
  Doc      => '

=for usage

    my ($m, $v) = $data->mme_lognormal();

=for ref

lognormal distribution. method of moments estimation.

=cut

  ',

);

pp_def('pdf_lognormal',
  Pars      => 'x(); m(); v(); float+ [o]p()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '

  if ( $x() > 0 && $v() > 0 ) {
    $p() = 1 / ($x() * sqrt($v() * 2 * M_PI))
	 * exp( -1 * pow(log($x()) - $m(), 2) / (2*$v()) );
  }
  else {
    barf( "x and v > 0 please" );
  }

  ',
  BadCode   => '

if ( $ISBAD($x()) || $ISBAD($m()) || $ISBAD($v()) ) {
  $SETBAD( $p() );
}
else {
  if ( $x() > 0 && $v() > 0 ) {
    $p() = 1 / ($x() * sqrt($v() * 2 * M_PI))
	 * exp( -1 * pow(log($x()) - $m(), 2) / (2*$v()) );
  }
  else {
    barf( "x and v > 0 please" );
  }
}

  ',
  Doc      => '

=for ref

probability density function for lognormal distribution. x > 0. v > 0.

=cut

  ',

);


pp_def('mme_nbd',
  Pars      => 'a(n); float+ [o]r(); float+ [o]p()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '
    $GENERIC(p) sa, a2, m, v;
    sa = 0; a2 = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
      a2 += pow($a(), 2);
    %}
    m = sa / N;
    v = a2 / N - pow(m, 2);
    $r() = pow(m, 2) / (v - m);
    $p() = m / v; 
  ',
  BadCode   => '
    $GENERIC(p) sa, a2, m, v;
    sa = 0; a2 = 0;
    long N = 0;
    loop (n) %{
      if ($ISGOOD( $a() )) {
	sa += $a();
	a2 += pow($a(), 2);
        N ++;
      }
    %}
    if (N) {
      m = sa / N;
      v = a2 / N - pow(m, 2);
      $r() = pow(m, 2) / (v - m);
      $p() = m / v; 
    }
    else {
      $SETBAD(r());
      $SETBAD(p());
    }
  ',
  Doc      => '

=for usage

    my ($r, $p) = $data->mme_nbd();

=for ref

negative binomial distribution. pmf: f(x; r,p) = (x+r-1  r-1) p^r (1-p)^x for x=0,1,2...

=cut

  ',

);

pp_def('pmf_nbd',
  Pars      => 'ushort x(); r(); p(); float+ [o]out()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '

  $GENERIC(out) nbc
    = gsl_sf_gamma($x()+$r()) / (gsl_sf_fact($x()) * gsl_sf_gamma($r()));
  $out() = nbc * pow($p(),$r()) * pow(1-$p(), $x());

  ',
  BadCode   => '

if ( $ISBAD($x()) || $ISBAD($r()) || $ISBAD($p()) ) {
  $SETBAD( $out() );
}
else {
  $GENERIC(out) nbc
    = gsl_sf_gamma($x()+$r()) / (gsl_sf_fact($x()) * gsl_sf_gamma($r()));
  $out() = nbc * pow($p(),$r()) * pow(1-$p(), $x());
}

  ',
  Doc      => '

=for ref

probability mass function for negative binomial distribution.

=cut

  ',

);


pp_def('mme_pareto',
  Pars      => 'a(n); float+ [o]k(); float+ [o]xm()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '
    $GENERIC(xm) sa, min;
    sa = 0; min = $a(n=>0);
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
      if (min > $a())
        min = $a();
    %}
    if (min > 0) {
      $k()  = (sa - min) / ( N*( sa/N - min ) );
      $xm() = (N * $k() - 1) * min / ( N * $k() );
    }
    else {
      barf("min <= 0!");
    }
  ',
  BadCode   => '
    $GENERIC(xm) sa, min;
    sa = 0; min = $a(n=>0);
    long N = 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
        sa += $a();
	if (min > $a())
	  min = $a();
        N ++;
      }
    %}
    if (min > 0) {
      $k()  = (sa - min) / ( N*( sa/N - min ) );
      $xm() = (N * $k() - 1) * min / ( N * $k() );
    }
    else {
      barf("min <= 0!");
    }
  ',
  Doc      => '

=for usage

    my ($k, $xm) = $data->mme_pareto();

=for ref

pareto distribution. pdf: f(x; k,xm) = k xm^k / x^(k+1) for x >= xm > 0.

=cut

  ',

);

pp_def('pdf_pareto',
  Pars      => 'x(); k(); xm(); float+ [o]p()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '

  if ( $xm() > 0 && $x() >= $xm() ) {
    $p() = $k() * pow($xm(),$k()) / pow($x(), $k()+1);
  }
  else {
    barf("x >= xm > 0 please");
  }

  ',
  BadCode   => '

if ( $ISBAD($x()) || $ISBAD($k()) || $ISBAD($xm()) ) {
  $SETBAD( $p() );
}
else {
  if ( $xm() > 0 && $x() >= $xm() ) {
    $p() = $k() * pow($xm(),$k()) / pow($x(), $k()+1);
  }
  else {
    barf("x >= xm > 0 please");
  }
}

  ',
  Doc      => '

=for ref

probability density function for pareto distribution. x >= xm > 0.

=cut

  ',

);

pp_def('mle_poisson',
  Pars      => 'a(n); float+ [o]l();',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => '
    $GENERIC(l) sa;
    sa = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
    %}
    $l()  = sa / N;
  ',
  BadCode   => '
    $GENERIC(l) sa;
    sa = 0;
    long N = 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
        sa += $a();
        N ++;
      }
    %}
    if (N) { $l()  = sa / N; }
    else   { $SETBAD(l()); }
  ',
  Doc      => '

=for usage

    my $lamda = $data->mle_poisson();

=for ref

poisson distribution. pmf: f(x;l) = e^(-l) * l^x / x!

=cut

  ',

);

pp_def('pmf_poisson',
  Pars      => 'x(); l(); float+ [o]p()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => q{

  if ($x() < 0) {
    $p() = 0;
  }
  else if ($x() < GSL_SF_FACT_NMAX / 2) {
    /* Exact formula */
    $p() = exp( -1 * $l()) * pow($l(),$x()) / gsl_sf_fact( (unsigned int) $x() );
  }
  else {
    /* Use Stirling's approximation. See
     * http://en.wikipedia.org/wiki/Stirling%27s_approximation
     */
    double log_p = $x() - $l() + $x() * log($l() / $x())
      - 0.5 * log(2*M_PI * $x()) - 1. / 12. / $x()
      + 1 / 360. / $x()/$x()/$x() - 1. / 1260. / $x()/$x()/$x()/$x()/$x();
    $p() = exp(log_p);
  }

  },
  BadCode   => q{

  if ( $ISBAD($x()) || $ISBAD($l()) ) {
    $SETBAD( $p() );
  }
  else {
    if ($x() < 0) {
      $p() = 0;
    }
    else if ($x() < GSL_SF_FACT_NMAX / 2) {
      /* Exact formula */
      $p() = exp( -1 * $l()) * pow($l(),$x()) / gsl_sf_fact( (unsigned int) $x() );
    }
    else {
      /* Use Stirling's approximation. See
       * http://en.wikipedia.org/wiki/Stirling%27s_approximation
       */
      double log_p = $x() - $l() + $x() * log($l() / $x())
        - 0.5 * log(2*M_PI * $x()) - 1. / 12. / $x()
        + 1 / 360. / $x()/$x()/$x() - 1. / 1260. / $x()/$x()/$x()/$x()/$x();
      $p() = exp(log_p);
    }
  }

  },
  Doc      => q{

=for ref

Probability mass function for poisson distribution. Uses Stirling's formula for x > 85.

=cut

  },

);

pp_def('pmf_poisson_stirling',
  Pars      => 'x(); l(); [o]p()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => q{

  if ($x() < 0) {
    $p() = 0;
  }
  else if ($x() == 0) {
    $p() = exp(-$l());
  }
  else {
    /* Use Stirling's approximation. See
     * http://en.wikipedia.org/wiki/Stirling%27s_approximation
     */
    double log_p = $x() - $l() + $x() * log($l() / $x())
      - 0.5 * log(2*M_PI * $x()) - 1. / 12. / $x()
      + 1 / 360. / $x()/$x()/$x() - 1. / 1260. / $x()/$x()/$x()/$x()/$x();
    $p() = exp(log_p);
  }

  },
  BadCode   => q{

  if ( $ISBAD($x()) || $ISBAD($l()) ) {
    $SETBAD( $p() );
  }
  else if ($x() < 0) {
    $p() = 0;
  }
  else if ($x() == 0) {
    $p() = exp(-$l());
  }
  else {
    /* Use Stirling's approximation. See
     * http://en.wikipedia.org/wiki/Stirling%27s_approximation
     */
    double log_p = $x() - $l() + $x() * log($l() / $x())
      - 0.5 * log(2*M_PI * $x()) - 1. / 12. / $x()
      + 1 / 360. / $x()/$x()/$x() - 1. / 1260. / $x()/$x()/$x()/$x()/$x();
    $p() = exp(log_p);
  }

  },
  Doc      => q{

=for ref

Probability mass function for poisson distribution. Uses Stirling's formula for all values of the input. See http://en.wikipedia.org/wiki/Stirling's_approximation for more info.

=cut

  },

);



pp_addpm(<<'EOD');

=head2 pmf_poisson_factorial

=for sig

  Signature: ushort x(); l(); float+ [o]p()

=for ref

Probability mass function for poisson distribution. Input is limited to x < 170 to avoid gsl_sf_fact() overflow.

=cut

*pmf_poisson_factorial = \&PDL::pmf_poisson_factorial;
sub PDL::pmf_poisson_factorial {
	my ($x, $l) = @_;

	my $pdlx = pdl($x);
	if (any( $pdlx >= 170 )) {
		croak "Does not support input greater than 170. Please use pmf_poisson or pmf_poisson_stirling instead.";
	} else {
		return _pmf_poisson_factorial(@_);
	}
}

EOD

pp_def('_pmf_poisson_factorial',
  Pars      => 'ushort x(); l(); float+ [o]p()',
  GenericTypes => [F,D],
  HandleBad => 1,
  Code      => q{

  if ($x() < GSL_SF_FACT_NMAX) {
    $p() = exp( -1 * $l()) * pow($l(),$x()) / gsl_sf_fact( $x() );
  }
  else {
    /* bail out */
    $p() = 0;
  }

  },
  BadCode   => q{

  if ( $ISBAD($x()) || $ISBAD($l()) ) {
    $SETBAD( $p() );
  }
  else {
    if ($x() < GSL_SF_FACT_NMAX) {
      $p() = exp( -1 * $l()) * pow($l(),$x()) / gsl_sf_fact( $x() );
    }
    else {
      $p() = 0;
    }
  }

  },
  Doc      => undef,

);

pp_addpm({At=>'Bot'}, <<'EOD');

=head2 plot_distr

=for ref

Plots data distribution. When given specific distribution(s) to fit, returns % ref to sum log likelihood and parameter values under fitted distribution(s). See FUNCTIONS above for available distributions. 

=for options

Default options (case insensitive):

    MAXBN => 20, 
      # see PDL::Graphics::PGPLOT::Window for next options
    WIN   => undef,   # pgwin object. not closed here if passed
                      # allows comparing multiple distr in same plot
                      # set env before passing WIN
    DEV   => '/xs' ,  # open and close dev for plotting if no WIN
                      # defaults to '/png' in Windows
    COLOR => 1,       # color for data distr

=for usage

Usage:

      # yes it threads :)
    my $data = grandom( 500, 3 )->abs;
      # ll on plot is sum across 3 data curves
    my ($ll, $pars)
      = $data->plot_distr( 'gaussian', 'lognormal', {DEV=>'/png'} );

      # pars are from normalized data (ie data / bin_size)
    print "$_\t@{$pars->{$_}}\n" for (sort keys %$pars);
    print "$_\t$ll->{$_}\n" for (sort keys %$ll);

=cut

*plot_distr = \&PDL::plot_distr;
sub PDL::plot_distr {
  if (!$PGPLOT) {
    carp "No PDL::Graphics::PGPLOT, no plot :(";
    return;
  }
  my ($self, @distr) = @_;

  my %opt = (
    MAXBN => 20, 
    WIN   => undef,     # pgwin object. not closed here if passed
    DEV   => $DEV,      # open and close default win if no WIN
    COLOR => 1,         # color for data distr
  );
  my $opt = pop @distr
    if ref $distr[-1] eq 'HASH';
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);

  $self = $self->squeeze;

    # use int range, step etc for int xvals--pmf compatible
  my $INT = 1
    if grep { /(?:binomial)|(?:geo)|(?:nbd)|(?:poisson)/ } @distr;

  my ($range, $step, $step_int);
  $range = $self->max - $self->min;
  $step  = $range / $opt{MAXBN};
  $step_int = ($range <= $opt{MAXBN})? 1 
            :                          PDL::ceil( $range / $opt{MAXBN} )
            ;
    # use min to make it pure scalar for sequence()
  $opt{MAXBN} = PDL::ceil( $range / $step )->min;

  my $hist = $self->double->histogram($step, $self->min, $opt{MAXBN});
    # turn fre into prob
  $hist /= $self->dim(0);

  my $xvals = $self->min + sequence( $opt{MAXBN} ) * $step;
  my $xvals_int
    = PDL::ceil($self->min) + sequence( $opt{MAXBN} ) * $step_int;
  $xvals_int = $xvals_int->where( $xvals_int <= $xvals->max )->sever;

  my $win = $opt{WIN};
  if (!$win) {
    $win = pgwin( Dev=>$opt{DEV} );
    $win->env($xvals->minmax,0,1, {XTitle=>'xvals', YTitle=>'probability'});
  }

  $win->line( $xvals, $hist, { COLOR=>$opt{COLOR} } );

  if (!@distr) {
    $win->close
      unless defined $opt{WIN};
    return;
  }

  my (%ll, %pars, @text, $c);
  $c = $opt{COLOR};        # fitted lines start from ++$c
  for my $distr ( @distr ) {
      # find mle_ or mme_$distr;
    my @funcs = grep { /_$distr$/ } (keys %PDL::Stats::Distr::);
    if (!@funcs) {
      carp "Do not recognize $distr distribution!";
      next;
    }
      # might have mle and mme for a distr. sort so mle comes first 
    @funcs = sort @funcs;
    my ($f_para, $f_prob) = @funcs[0, -1];

    my $nrmd = $self / $step;
    eval {
      my @paras = $nrmd->$f_para();
      $pars{$distr} = \@paras;
  
      @paras = map { $_->dummy(0) } @paras;
      $ll{$distr} = $nrmd->$f_prob( @paras )->log->sumover;
      push @text, sprintf "$distr  LL = %.2f", $ll{$distr}->sum;

      if ($f_prob =~ /^pdf/) { 
        $win->line( $xvals, ($xvals/$step)->$f_prob(@paras), {COLOR=>++$c} );
      }
      else {
        $win->points( $xvals_int, ($xvals_int/$step_int)->$f_prob(@paras), {COLOR=>++$c} );
      }
    };
    carp $@ if $@;
  }
  $win->legend(\@text, ($xvals->min + $xvals->max)/2, .95,
               {COLOR=>[$opt{COLOR}+1 .. $c], TextFraction=>.75} );
  $win->close
    unless defined $opt{WIN};
  return (\%ll, \%pars);
}

=head1 DEPENDENCIES

GSL - GNU Scientific Library

=head1 SEE ALSO

PDL::Graphics::PGPLOT

PDL::GSL::CDF

=head1 AUTHOR

Copyright (C) 2009 Maggie J. Xiong <maggiexyz users.sourceforge.net>, David Mertens

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDL distribution.

=cut

EOD

pp_done();
