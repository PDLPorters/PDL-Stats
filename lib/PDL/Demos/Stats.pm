package PDL::Demos::Stats;

use PDL::Graphics::Simple;

sub info {('stats', 'Statistics, linear modelling (Req.: PDL::Graphics::Simple)')}

sub init {'
use PDL::Graphics::Simple;
'}

my @demo = (
[act => q|
# This demo illustrates the PDL::Stats module,
# which lets you analyse statistical data in a number of ways.

use PDL::Stats;
$w = pgswin(); # PDL::Graphics::Simple window
srandom(5); # for reproducibility
|],

[act => q|
# First, PDL::Stats::TS - let's show three sets of random data, against
# the de-seasonalised version
$data = random(12, 3);
$data->plot_dseason( 12, { win=>$w } );
|],

[act => q|
# Now let's show the seasonal means of that data
($m, $ms) = $data->season_m( 6, { plot=>1, win=>$w } );
print "m=$m\nms=$ms";
|],

[act => q|
# Now, auto-correlation of a random sound-sample.
# See https://pdl.perl.org/advent/blog/2024/12/15/pitch-detection/ for more!
random(100)->plot_acf( 50, { win=>$w } );
|],

[act => q|
# PDL::Stats::Kmeans clusters data points into "k" (a supplied number) groups
$data = grandom(200, 2); # two rows = two dimensions
%k = $data->kmeans; # use default of 3 clusters
print "$_\t$k{$_}\n" for sort keys %k;
$w->plot(
  (map +(with=>'points', style=>$_+1, ke=>"Cluster ".($_+1),
    $data->dice_axis(0,which($k{cluster}->slice(",$_")))->dog),
    0 .. $k{cluster}->dim(1)-1),
  (map +(with=>'circles', style=>$_+1, ke=>"Centroid ".($_+1), $k{centroid}->slice($_)->dog, 0.1),
    0 .. $k{centroid}->dim(0)-1),
  {le=>'tr'},
);
|],

[comment => q|
This concludes the demo.

Be sure to check the documentation for PDL::Stats, to see further
possibilities.
|],
);

sub demo { @demo }
sub done {'
undef $w;
'}

1;
