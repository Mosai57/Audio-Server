#!/usr/bin/env perl
use strict;
use warnings;
use DBI qw(:sql_types);
my $now_playing = `cat /home/pi/.now_playing`;

my $dbname = "/db/Songs.sdb";
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname");

my $search = $dbh->prepare(q{
    SELECT Title, Artist, Album, TrackNo, DiscNo, Genre, ReleaseDate
    FROM Songs
    WHERE FilePath==?1;
});

$search->execute($now_playing);

my @results = $search->fetchrow_array();
my @labels = ("Title", "Artist", "Album", "TrackNo", "DiscNo", "Genre", "Release Date");

if(@results){
    foreach(0..6){
        if($results[$_]){
            print sprintf "% 12s : %s\n", $labels[$_], $results[$_];
        }
    }
}else{
    print "$now_playing\n";
}
