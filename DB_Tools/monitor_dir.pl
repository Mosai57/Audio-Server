use strict;
use warnings;
use File::Monitor;
use File::Find;
use Cwd;
my $cwd = getcwd;

my $dir = "/music/Music";
my $song_pattern = ".*\.(mp3|m4a|flac|wav)";

my $monitor = File::Monitor->new();

$monitor->watch({
        name     => $dir,
        recurse  => 1
});

my @changes;
while(1){
    # Capture any events that happen to the directory we are watching
    @changes = $monitor->scan;
    for my $change (@changes){
        my @add_files = $change->files_created;
        my @del_files = $change->files_deleted;
        foreach(@add_files){
            if($_ =~ /$song_pattern$/){
                print "Adding $_\n";
                system("/usr/bin/perl", "$cwd/add_to_db.pl", "$_");
            }
        }
        foreach(@del_files){
            if($_ =~ /$song_pattern$/){
                print "Deleting $_\n";
                system("/usr/bin/perl", "$cwd/del_from_db.pl", "$_");
            }
        }
    }
    # Clear out the events to ensure that theyre not repeated.
    undef @changes;
}
