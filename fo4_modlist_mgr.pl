#!/usr/bin/perl

use strict;
use warnings;

use Config::Tiny;
use Digest::SHA qw(sha256_hex);
use File::Copy;
use File::Find;
use File::Path qw(make_path remove_tree);
use File::Slurp qw(read_file);
use Getopt::Long;

my $opt_verbose;
my $opt_save;
my $opt_restore;
my $opt_force;
my $opt_dryrun;
my $opt_clean;
GetOptions ("save=s"    => \$opt_save,
            "restore=s" => \$opt_restore,
            "verbose|v"   => \$opt_verbose,
            "force|f"   => \$opt_force,
            "dryrun|n"  => \$opt_dryrun,
            "clean" => \$opt_clean)
or die("Error in command line arguments\n");

my $n_cmds = 0;
$n_cmds++ if $opt_save;
$n_cmds++ if $opt_restore;
$n_cmds++ if $opt_clean;
if (!$n_cmds) {
    die "no command given";
}
if ($n_cmds >= 2) {
    die "more than one command given";
}

#
# clean/remove unpacked files
#

if ($opt_clean) {
    my @files = ();
    find({ wanted => sub {
        my $fn = $_;
        if ((-d $fn) && $fn =~ /\.unpack$/i && split("/", $fn)==2) {
            push @files, $fn;
        }
        elsif ((-f $fn) && $fn =~ /\.unpack.sha256$/i && split("/", $fn)==2) {
            push @files, $fn;
        }
    }, no_chdir => 1 }, "downloads");
    foreach my $fn (sort @files) {
        remove_tree($fn) or die $!;
    }
    exit 0;
}

#
# copy with automatic parent directory creation
#

sub copy_mk {
    my $src = shift;
    my $dest = shift;

    if ($dest =~ /^(.+)\//) {
        my $pdir = $1;
        unless (-d $pdir) {
            print "creating directory $pdir\n" if $opt_verbose;
            make_path($pdir) or die $!;
        }
    }
    die "target alrady exists: $dest" if -e $dest;
    copy($src, $dest) or die $!;
    if ($dest =~ /\.(dll|exe)$/i) {
        unless (-x $dest) {
            print "making $dest executable\n" if $opt_verbose;
            chmod(0755, $dest) or die $!;
        }
    }
    return 1;
}

#
# find Steam Fallout 4 installation
#

my $fo4srcdir="";
foreach my $drive (split(" ", "c d e f g h i j k l m n")) {
    my $fo4relp="/SteamLibrary/steamapps/common/Fallout 4";
    if (-f "/cygdrive/$drive$fo4relp/Fallout4.exe") {
        $fo4srcdir="/cygdrive/$drive$fo4relp";
        last;
    }
}
die unless -f "$fo4srcdir/Fallout4.exe";

#
# update base game file sigs
#

my %fo4cache = ();
my $fo4cache_fn = "fo4_base.cache";
sub load_fo4_cache {
    %fo4cache = ();
    return unless -e $fo4cache_fn;
    open my $fh, "<", $fo4cache_fn or die $!;
    while(<$fh>) {
        chomp;
        die unless /^([0-9a-f]{64,64}) ([0-9]+) ([^\r\n]+)$/;
        $fo4cache{lc($3)} = {sha => $1, lmod => $2};
    }
    close $fh;
}
sub save_fo4_cache {
    open my $fh, ">", $fo4cache_fn or die $!;
    foreach my $f (sort keys %fo4cache) {
        my $ref = $fo4cache{$f} or die;
        next unless $ref->{'used'};
        print $fh $ref->{sha}, " ", $ref->{lmod}, " ", $f, "\n";
    }
    close $fh;
}
sub update_fo4_cache {
    print "updating base game file signatures: $fo4srcdir\n";
    my @files = ();
    find({ wanted => sub {
        if ((-f $_)) {
            push @files, $_;
        }
    }, no_chdir => 1 }, $fo4srcdir);

    load_fo4_cache();
    foreach my $f (@files) {
        my $lmod = (stat($f))[9] or die $!;

        if (defined $fo4cache{lc($f)}) {
            my $cache_lmod = $fo4cache{lc($f)}->{'lmod'} or die;
            if ($cache_lmod == $lmod) {
                $fo4cache{lc($f)}->{'used'} = 1;
                next;
            }
        }

        my $sha = Digest::SHA->new('sha256');
        $sha->addfile($f);

        $fo4cache{lc($f)} = {sha => $sha->hexdigest, lmod => $lmod, used => 1};
    }
    save_fo4_cache();
    print "Saved.\n";
}
update_fo4_cache();

#
# where to save snapshots
#

mkdir "snapshots" unless -d "snapshots";

#
# download unmanaged archives
#

mkdir "downloads" unless -d "downloads";

sub wget {
    my $fp=shift;
    my $url=shift;
    if (!defined($url)) {
        $url = $fp;
        $fp =~ s/^.*\///;
        $fp = "downloads/$fp";
    }
    return if -e $fp;
    if (system("wget", "-O", $fp, $url)) {
        unlink $fp if (-f $fp);
        die $!;
    }
}

sub download_manual_urls {
    my $manual_list = "manual_urls.txt";
    return unless -e $manual_list;
    open my $fh, "<", $manual_list or die $!;
    while (<$fh>) {
        chomp;
        s/^\s+//;
        s/\s+$//;
        next unless $_;
        wget($_);
    }
    close $fh;
}

#
# You'll need a premium account with nexus mods in order for automatic downlodas to work.
# Otherwise you can also click each plugin in MO2 and select "visit nexuis mod page" to
# download them one by one manually.
#

#
# get your personal API key at the bottom of: https://www.nexusmods.com/users/myaccount?tab=api+access
# and put it into %LOCALAPPDATA%\nexusmods_apikey file.
#

my $apikeyfile=`cygpath "$ENV{LOCALAPPDATA}/nexusmods_apikey"` or die $!;
chomp($apikeyfile);
die "get your personal API key from: https://www.nexusmods.com/users/myaccount?tab=api+access\n"
    ."and put it into $apikeyfile" unless -e $apikeyfile;
my $apikey = read_file($apikeyfile);
$apikey =~ s/[\r\t\n ]//g;

#
# download mo2-managed archives
#

sub download_nexus_mods {
    my @metainis = ();
    find({ wanted => sub {
        if ((-f $_) && /\/meta\.ini$/i && split("/")==3) {
            push @metainis, $_;
        }
    }, no_chdir => 1 }, "mods");
    print "Detected ".(scalar @metainis)." mods\n";

    print "Downloading files from nexus...\n";
    foreach my $metaini (@metainis) {
        my $cfg = Config::Tiny->read($metaini);

        my $modfn = $cfg->{'General'}->{'installationFile'};
        next unless $modfn;

        # if ($cfg->{'General'}->{'hasCustomURL'} eq "true") {
        #     print "skipped because of custom url: $metaini\n";
        #     next;
        # }
        if (!$cfg->{'installedFiles'}->{'size'}) {
            print "skipped because of no installed files: $metaini\n";
            next;
        }

        my $modid = $cfg->{'General'}->{'modid'};
        die "no modid in $metaini" unless defined $modid;
        if (!$modid) {
            print "skipped because modid is zero: $metaini\n";
            next;
        }

        my $fileid = $cfg->{'installedFiles'}->{'1\\fileid'} or die "no fileid in $metaini";

        next if -e "downloads/$modfn";
        print "$metaini => $modfn\n";

        my $output=`curl -X 'GET' "https://api.nexusmods.com/v1/games/fallout4/mods/$modid/files/$fileid/download_link.json" \\
            -H 'accept: application/json' -H "apikey: $apikey"` or die $!;
        die unless $output =~ /"URI":"([^"]+)"/;
        my $fileurl=$1;
        $fileurl =~ s/\\u0026/&/g;
        wget("downloads/$modfn", $fileurl);
    }
    print "Nexus downloads finished.\n";
}

#
# load list and sigs of to-be-installed mod files
#

sub load_sha_list {
    my $fn = shift;
    my $href = shift;
    open my $fh, "<", "$fn" or die $!;
    while(<$fh>) {
        chomp;
        die unless /^([0-9a-f]{64,64}) [ *]([^\r\n]+)$/;
        $href->{$2} = $1;
    }
    close $fh;
}

#
# unpack and index downloaded archives
#

sub unpack_archives {
    my @archives = ();
    find({ wanted => sub {
        if ((-f $_) && /\.(zip|rar|7z)$/i && split("/")==2) {
            push @archives, $_;
        }
    }, no_chdir => 1 }, "downloads");

    my @files = ();

    sub compute_sha_for_file {
        my $fn = shift;
        die unless defined $fn;
        my $sha = Digest::SHA->new('sha256');
        $sha->addfile($fn);
        return $sha->hexdigest;
    }

    foreach my $archive (@archives) {
        next if -d "$archive.unpack";
        if ($archive =~ /\.rar$/i) {
            system("unrar", "x", "-op$archive.unpack", $archive) and die $!;
        } else {
            system("7z", "x", "-o$archive.unpack", $archive) and die $!;
        }
        @files = ();
        find({ wanted => sub {
            if ((-f $_) && split("/")>2) {
                push @files, $_;
            }
        }, no_chdir => 1 }, "$archive.unpack");
        open my $fh, ">", "$archive.unpack.sha256" or die $!;
        foreach my $f (@files) {
            my $sha = compute_sha_for_file($f);
            print $fh "$sha *$f\n";
        }
        close $fh;
    }
}

unpack_archives();

#
# load file signatures of all unpacked files
#

my %lookup = ();
sub load_lookup_table {
    my @shafiles = ();
    %lookup = ();
    find({ wanted => sub {
        if ((-f $_) && /\.unpack.sha256$/ && split("/")==2) {
            push @shafiles, $_;
        }
    }, no_chdir => 1 }, "downloads");

    my %srcfiles = ();
    foreach my $shafile (@shafiles) {
        load_sha_list($shafile, \%srcfiles);
    }
    print "Index initialized with ", scalar keys %srcfiles, " files from ", scalar @shafiles, " archives.\n";
    foreach my $srcfile (keys %srcfiles) {
        $lookup{$srcfiles{$srcfile}} = $srcfile;
    }
    # add Steam FO4 installation to sha lookup hash
    foreach my $srcfile (keys %fo4cache) {
        $lookup{$fo4cache{$srcfile}->{'sha'}} = $srcfile;
    }
}
load_lookup_table();

sub add_snapshot_files_to_lookup_table {
    my $snapdir = shift or die;

    my @files = ();
    find({ wanted => sub{
        if ((-f $_) && !/^snapshots\/[^\/]+\/list\.txt$/i) {
            push @files, $_;
        }
    }, no_chdir => 1 }, $snapdir);

    foreach my $f (@files) {
        my $sha = compute_sha_for_file($f);
        $lookup{$sha} = $f;
    }
}

# 
# determine whether a file is managed via --save/--restore
#

sub is_managed {
    return 0 if(/^downloads\//i && !/^downloads\/[^\/]+\.meta/i);
    return 0 if(/^snapshots\//i);
    return 0 if(/^webcache\//i);
    return 0 if(/^splash\.png$/i);
    return 0 if(/^[^\/]+\.cache$/i);
    return 0 if(/^plugins\/.*\.pyc$/i);
    return 0 if(/\.log$/i);
    return 0 if(/^[^\/]+\.pl$/i);
    return 1;
}

#
# file sigs of currently active file set
#

my %shacache = ();
my $shacache_fn = "sha256.cache";
sub load_sha_cache {
    %shacache = ();
    return unless -e $shacache_fn;
    open my $fh, "<", $shacache_fn or die $!;
    while(<$fh>) {
        chomp;
        die unless /^([0-9a-f]{64,64}) ([0-9]+) ([^\r\n]+)$/;
        $shacache{lc($3)} = {sha => $1, lmod => $2};
    }
    close $fh;
}
sub save_sha_cache {
    open my $fh, ">", $shacache_fn or die $!;
    foreach my $f (sort keys %shacache) {
        my $ref = $shacache{$f} or die;
        next unless $ref->{'used'};
        print $fh $ref->{sha}, " ", $ref->{lmod}, " ", $f, "\n";
    }
    close $fh;
}
sub update_sha_cache {
    print "Compiling list of files currently in use...\n";
    my @files = ();
    find({ wanted => sub {
        if ((-f $_)) {
            s/^\.\/// or die ">>$_\n";
            return unless is_managed($_);
            push @files, $_;
        }
    }, no_chdir => 1 }, ".");

    load_sha_cache();
    foreach my $f (@files) {
        my $lmod = (stat($f))[9] or die $!;

        if (defined $shacache{lc($f)}) {
            my $cache_lmod = $shacache{lc($f)}->{'lmod'} or die;
            if ($cache_lmod == $lmod) {
                $shacache{lc($f)}->{'used'} = 1;
                next;
            }
        }

	    my $sha = Digest::SHA->new('sha256');
	    $sha->addfile($f);

        $shacache{lc($f)} = {sha => $sha->hexdigest, lmod => $lmod, used => 1};
    }
    save_sha_cache();
    print "Saved.\n";
}

sub restore {
    my $files = shift or die;
    my $best_effort = shift;

    my $cnt_missing = 0;
    foreach my $fn (sort keys %$files) {
        my $ref = $files->{lc($fn)} or die;
        my $sha = $ref->{'sha'} or die;

        next if $ref->{'done'};

        # check existing file's checksum:
        if (-e $fn) {
            die unless exists $shacache{lc($fn)}; # existing active files should always be in current sha cache
            my $existing_sha = $shacache{lc($fn)}->{'sha'} or die;
            if ($sha eq $existing_sha) {
                $ref->{'done'} = 1;
                next;
            }

            # delete on mismatch
            print "deleting $fn\n" if $opt_verbose;
            unless ($opt_dryrun) {
                unlink $fn or die $!;
            }
        }

        # restore file from archives/base game/snapshot data
        if (exists $lookup{$sha}) {
            print "restoring $fn from ", $lookup{$sha}, "\n" if $opt_verbose;
            die unless -f $lookup{$sha};
            unless ($opt_dryrun) {
                copy_mk($lookup{$sha}, $fn) or die $!;
            }
            $ref->{'done'} = 1;
            next;
        }
        else {
            $cnt_missing++;
            print "cannot resolve: $fn (sha256 $sha)\n" unless ($best_effort && !$opt_verbose);
        }
    }
    return ($cnt_missing == 0);
}

#
# execute --restore command
#

if (defined($opt_restore)) {
    die unless $opt_restore =~ /^[a-zA-Z0-9_-]+$/;
    my $snapdir = "snapshots/$opt_restore";
    die unless -d $snapdir;

    update_sha_cache();

    print "Reading snapshot file list\n";

    open my $fh, "<", "$snapdir/list.txt" or die $!;
    my %files = ();
    while(<$fh>) {
        chomp;
        /^([0-9a-f]{64,64}) ([^\r\n]+)$/ or die "$_";
        $files{lc($2)} = {sha => $1};
    }
    close $fh;

    print "Indexing snapshot data\n";

    add_snapshot_files_to_lookup_table($snapdir);

    # remove files not in snapshot file list
    foreach my $fn (sort keys %shacache) {
        # existing file not in snapshot?
        unless (exists $files{lc($fn)}) {
            print "deleting $fn\n" if $opt_verbose;
            unless ($opt_dryrun) {
                if (-e $fn) {
                    unlink $fn or die $!;
                }
            }
        }
    }

    print "Restoring files...\n";

    # snapshot data contains download information
    #  => if we cannot resolve all files, restore all that we can,
    #     then start downloads, and retry.
    if(!restore(\%files, 1)) {
        download_manual_urls();
        download_nexus_mods();
        unpack_archives();
        load_lookup_table();
        add_snapshot_files_to_lookup_table($snapdir);
        print "Restoring files (2nd and last try)...\n";
        restore(\%files, 0) or die "failed to resolve some files";
    }

    print "Snapshot restored from: $snapdir\n";
}

#
# execute --save command
#

elsif (defined($opt_save)) {
    die unless $opt_save =~ /^[a-zA-Z0-9_-]+$/;

    my $snapdir = "snapshots/$opt_save";

    if (-e $snapdir) {
        if ($opt_force) {
            remove_tree($snapdir, {safe => 1}) or die $!;
        }
        else {
            die "snapshot already exists: $opt_save";
        }
    }
    die if -e $snapdir;
    make_path($snapdir) or die $!;

    update_sha_cache();

    open my $fh, ">", "$snapdir/list.txt" or die $!;
    foreach my $f (sort keys %shacache) {
        my $ref = $shacache{$f} or die;
        next unless $ref->{'used'};
        print $fh $ref->{sha}, " ", $f, "\n";
        if (not exists $lookup{$ref->{sha}}) {
            print "unresolved: $f (", $ref->{sha}, ")\n";
            copy_mk($f, "$snapdir/$f") or die $!;
        }
    }
    close $fh;

    print "Snapshot saved to: $snapdir\n";
}
else {
    die "no command given";
}
