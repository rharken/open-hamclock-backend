#!/usr/bin/perl
# web15rss.pl — client-facing, called by HamClock clients via OHB
# NEVER fetches from the network. Reads only from cache.
# If a cache file is missing, that source is silently skipped.

use strict;
use warnings;
use Encode;

my $CACHE_DIR = '/opt/hamclock-backend/cache/rss';

# NG3K is the only source needing ISO-8859-1 for HamClock compatibility.
# All others are UTF-8.
my @sources = (
    { name => 'arnewsline', encoding => 'UTF-8'       },
    { name => 'ng3k',       encoding => 'ISO-8859-1'  },
    { name => 'hamweekly',  encoding => 'UTF-8'       },
);

for my $src (@sources) {
    my $path = "$CACHE_DIR/$src->{name}.txt";
    next unless -f $path && -r $path;

    open my $fh, '<:encoding(UTF-8)', $path or next;

    binmode(STDOUT, ":encoding($src->{encoding})");

    while (my $line = <$fh>) {
        chomp $line;
        print "$line\n";
    }

    close $fh;
}
