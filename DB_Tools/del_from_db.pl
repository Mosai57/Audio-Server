use strict;
use warnings;

use DBI qw(:sql_types);

my $db_name = "/db/Songs.sdb";
my $dbh = DBI->connect("dbi:SQLite:dbname=$db_name");

my $to_delete = $ARGV[0];
my $delete = $dbh->prepare(q{
    DELETE FROM Songs WHERE filePath=?1
});

$delete->execute($to_delete);
