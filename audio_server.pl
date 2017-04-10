#!/usr/bin/perl -s
use strict;
use warnings;
use File::ChangeNotify;
use File::Find;
use Cwd;
my $cwd = getcwd;

our $test;
our $cycles; $cycles //= 1_000_000;

our $focus; $focus //= "/music/Music";

# returns an arrayref containing every directory we'll ever want to play
sub get_disc_list;

# get_song_list($path) gets the list of song files in $path
sub get_song_list;

# I use cvlc for audio streaming.
# The root path we will be following is /music
# since that is where the drive will be mounted.
my $vlc = "/usr/bin/cvlc";
my $root = $focus;
my %plays;

# Default regex patterns I use in this script
my $sng_pattern = qr/\.(mp3|m4a|wav|flac)$/;

sub play_selection;

# read the system to find out what files are there
my $disc_list = get_disc_list();

# set up a filesystem watcher so we find out if someone adds/removes files
my $watcher =
        File::ChangeNotify->instantiate_watcher(
                directories => [$root],
        );

# the last disc we played, to eliminate repeats
my $last_played = '';

# Main body to repeat forever until the process is killed
while(1){
	if ($watcher->new_events) {
		print "Filesystem change detected. Re-scanning...\n";
		$disc_list = get_disc_list();
	}
	
	my $path = get_random_disc(@$disc_list);

	my @songs;
	
    # Make sure that 1) we havent just played the disc it wants to play and
    # 2) That it has actually selected a disc to play.
    if($path ne $last_played && (@songs = get_song_list($path))) {
		my $count = 1;
        print "Playing $path\n";
		foreach(@songs){
			# Make a pretty output to tell which song
			# is currently playing.

            my $basename = $_; $basename =~ s/$sng_pattern//;
			my $cur_status = " - Playing $basename  (" . 
			sprintf("%03d", $count) . "/" . 
			sprintf("%03d", scalar(@songs)) . ")\n";
			print $cur_status;
		
            if(!$test){
                open(my $fh, '>', "/home/pi/.now_playing");
                print $fh "$path/$_";
                close $fh;
            }
			play_selection("$path/$_");
		
			$count++;
		}
	}
    # Save the last path so we dont play it again and reset
    # the current path.
    $last_played = $path;
    $plays{$path} = time;
}

sub play_selection {
	my $selection = shift;
	if ($test) {
		open(my $tmp, '>>', 'audio_server_selections.log');
		print $tmp $selection, "\n";
		exit unless --$cycles;
	} else { 
            system($vlc, "--no-video", "--play-and-exit", "-q", $selection);
	}
}

sub get_song_list {
	my $path = shift;
	my @songs;
	if($path){
        find(sub {
		    if (-d $_) { $File::Find::prune = 1 unless $_ eq '.'; return; }
		    if (-f $_ && $_ =~ $sng_pattern) { 
			    push @songs, $_;
		    }
	    }, $path);
	    return sort @songs;
    }else{
        return undef;
    }
}

sub get_disc_list {
	my @discs;
	my %discs;
	
	# find all directories with playable files
	find(sub {
		if (-f $_ && $_ =~ $sng_pattern) {
			my $dir = $File::Find::dir;
			unless ($discs{$dir}) {
				push @discs, $dir;
				$discs{$dir} = 1;
			}
		}
	}, $root);
	
	@discs = sort @discs;
	
	print "Completed filesystem scan. Found ", 0+@discs, " folders.\n";
	
	return \@discs;
}

sub get_random_disc {
    my $disc;
    my $total_weight = 0;
    my $time = time();
    foreach(@$disc_list){
        my $weight = $time;
        my $age = $time - ($plays{$_} // 0);
        if($age < 1) { $age = 1; }
        elsif($age > 86400 * 30) { $age = 86400 * 30; }
        $weight = sqrt($age);
        $total_weight += $weight;
        $disc = $_ if rand($total_weight) < $weight;
    }
    if($disc){
        return $disc;
    }else{
        return undef;
    }
}
