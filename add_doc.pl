use Cwd;
use PDL::Doc;
use File::Copy qw(copy);


# Find the pdl documentation
my ($dir,$file,$pdldoc);

DIRECTORY:
for (@INC) {
    $dir = $_;
    $file = $dir."/PDL/pdldoc.db";
    if (-f $file) {
        print "Found docs database $file\n";
        $pdldoc = new PDL::Doc ($file);
        last DIRECTORY;
    }
}

die ("Unable to find docs database! Not updating docs database.\n") unless $pdldoc;

chdir 'blib/lib' or die "can't change to blib/lib";

$current_dir = getcwd;

#$pdldoc->outfile('pdldoc.db');

$pdldoc->ensuredb();
$pdldoc->scantree("$current_dir/PDL");
$pdldoc->scan("$current_dir/PDL/Stats.pm");
$pdldoc->savedb();

print STDERR "PDL docs database updated.\n";
