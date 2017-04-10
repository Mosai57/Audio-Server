use strict;
use warnings;
use File::ChangeNotify;
use File::Find;
use Cwd;
my $cwd = getcwd;

my $dir = "/music/Music";
my $sng_pattern = "\.(mp3|m4a|flac|wav)";

sub get_dir_contents;

my $watcher = 
    File::ChangeNotify->instantiate_watcher(
        directories => [$dir],
    );

my $dir_contents = get_dir_contents();

for my $dir (@$dir_contents){
    print "$dir\n";
    opendir(my $handle, "$dir/") || die "Cannot open $dir for reading. $!";
    my @files = sort grep{ /$sng_pattern/ } readdir($handle);
    for my $file (@files){
        print "Adding $dir/$file\n";
        system("/usr/bin/perl", "$cwd/add_to_db.pl", "$dir/$file");
    }
}

sub get_dir_contents {
    my @dirs;
    my %dirs;

    find(sub {
            if(-f $_ && $_ =~ $sng_pattern){
                my $dir = $File::Find::dir;
                unless ($dirs{$dir}){
                    push @dirs, $dir;
                    $dirs{$dir} = 1;
                }
            }
        }, $dir);

    @dirs = sort @dirs;

    print "Completed filesystem scan. Found ", 0+@dirs, " folders.\n";

    return \@dirs;
}
