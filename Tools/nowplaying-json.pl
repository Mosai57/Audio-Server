#!/usr/bin/env perl
use strict;
use warnings;
use DBI qw(:sql_types);
use JSON::PP qw/encode_json/;

my $now_playing = `cat /home/pi/.now_playing`;

my $dbname = "/db/Songs.sdb";
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname");

my $search = $dbh->prepare(q{
    SELECT Title, Artist, Album, TrackNo, DiscNo, Genre, ReleaseDate
    FROM Songs
    WHERE FilePath==?1;
});

$search->execute($now_playing);

my $results = $search->fetchrow_hashref() || { Title => $now_playing };

my $result_data = encode_json($results);

print <<HERE;
Content-Type: text/json;charset=utf-8
Content-Length: @{[length $result_data]}

HERE

print $result_data;

1;

