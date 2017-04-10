use strict;
use warnings;
use DBI qw(:sql_types);
use Cwd;
my $cwd = getcwd;

my $dbname = "/db/Songs.sdb";
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname");

my @search_tags = ("TITLE", "ARTIST", "ALBUM", "DISCNUMBER", "TRACKNUMBER", "GENRE", "DATE");
my @results;
my $file_path = $ARGV[0];
my @sha1 = split(/\s+/, `sha1sum "$file_path"`);
push @results, $file_path;
push @results, $sha1[0];

my $tags = `/usr/bin/python $cwd/extract_metadata.py "$file_path"`;

my @tags = split(', ', $tags);
s/[{}\[\]]|(u('|"))|'|"//ig for @tags;

sub get_tag {
    my $tag = shift;
    my $to_return;
    foreach(@tags){
        if($_ =~ /^$tag: /){ 
            $to_return = $_;
        }
    }
    if($to_return){
        s/$tag: // for $to_return;
        chomp $to_return;
        return $to_return;
    }else{
        return undef;
    }
}

foreach(@search_tags){
    my $tag = get_tag($_);
    $tag ||= undef;
    push @results, $tag;
} 

foreach(5..6){
    if($results[$_]){
        if($results[$_] =~ /^(\d+)\/\d+$/){ 
            $results[$_] = $1; 
        }
    }
}

my $insert = $dbh->prepare(q{
    INSERT INTO Songs VALUES(?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10);
});

$insert->execute(
    undef,       # RowID
    $results[0], # FilePath
    $results[1], # Sha1
    $results[2], # Title
    $results[3], # Artist
    $results[4], # Album
    $results[5], # DiscNo
    $results[6], # TrackNo
    $results[7], # Genre
    $results[8]  # Date
);
