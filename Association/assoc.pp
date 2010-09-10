#!/usr/bin/perl

pp_addpm({At=>'Top'}, <<'EOD');

=head1 NAME

PDL::Stats::Association -- functions for various association measures.

=head1 DESCRIPTION

The terms FUNCTIONS and METHODS are arbitrarily used to refer to methods that are threadable and methods that are NOT threadable, respectively. Plots require PDL::Graphics::PGPLOT.

=head1 SYNOPSIS

    use PDL::LiteF;
    use PDL::NiceSlice;
    use PDL::Stats::Misc;


=cut

use Carp;
use PDL::LiteF;
use PDL::NiceSlice;

$PDL::onlinedoc->scan(__FILE__) if $PDL::onlinedoc;

my $PGPLOT;
  # check for PGPLOT not PDL::Graphics::PGPLOT
if ( grep { -e "$_/PGPLOT.pm"  } @INC ) {
  require PDL::Graphics::PGPLOT::Window;
  PDL::Graphics::PGPLOT::Window->import( 'pgwin' );
  $PGPLOT = 1;
}

EOD

pp_addhdr('
#include <math.h>

'
);

pp_def('pmi',
  Pars  => 'pab(i,j); pa(i); pb(j); double [o]pmi(i,j)',
  GenericTypes => [D],
  HandleBad    => 1,
  Code  => '

loop(i) %{
  loop(j) %{
    $pmi() = log10( $pab() / ( $pa() * $pb() ) );
  %}
%}

',
  BadCode  => '

loop(i) %{
  loop(j) %{
    if ( $ISBAD(pab()) || $ISBAD(pa()) || $ISBAD(pb()) ) {
      $SETBAD(pmi());
    }
    else {
      $pmi() = log10( $pab() / ( $pa() * $pb() ) );
    }
  %}
%}


',
  Doc   => '

=for ref

Pointwise Mutual Information. PMI(a,b) = log10( p(a,b) / (p(a) * p(b)) ).

=for usage

Usage:

    $pmi = $p_ab->pmi( $p_a, $p_b );

=cut

',
);

pp_def('tf_idf',
  Pars  => 'td(i,j); d(j); double [o]w(i,j)',
  GenericTypes => [D],
  HandleBad    => 0,
  Code  => '
double lgND, lgTD, TD[$SIZE(i)];
lgND = log10( $SIZE(j) );

loop(i) %{
  TD[i] = 0;
  loop(j) %{
    if ($td()) {
      TD[i] ++;
    }
  %}
%}

loop(i) %{
  lgTD = log10( TD[i] );
  loop(j) %{
    $w() = $td() / $d() * (lgND - lgTD);
  %}
%}

',
  Doc   => '

=for ref

Term frequency x inverse document frequency. TF = fre_of_term_in_doc / doc_size, IDF = log10( total_Doc / term_Doc ).

=for usage

Usage:

  # assuming $td include all terms in the corpus

  my $tf_idf = $td->tf_idf( $td->sumover );

=cut

',
);

pp_addpm(<<'EOD');

=head1 	REFERENCES

=head1 AUTHOR

Copyright (C) 2010 Maggie J. Xiong <maggiexyz users.sourceforge.net>

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDL distribution.

=cut

EOD

pp_done();
