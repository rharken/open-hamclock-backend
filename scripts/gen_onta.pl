#!/usr/bin/env perl
use strict;
use warnings;

use LWP::UserAgent;
use JSON qw(decode_json);
use Time::Local;

my $URL = 'https://api.pota.app/spot';
my $OUT = '/opt/hamclock-backend/htdocs/ham/HamClock/ONTA/onta.txt';
my $TMP = "$OUT.tmp";

my $ua = LWP::UserAgent->new(
    timeout => 10,
    agent   => 'HamClock-Backend/1.0',
);

my $resp = $ua->get($URL);
die "Fetch failed\n" unless $resp->is_success;

my $spots = decode_json($resp->decoded_content);
die "Bad JSON\n" unless ref $spots eq 'ARRAY';

open my $fh, '>', $TMP or die "Cannot write temp file\n";

# Header exactly as HamClock expects
print $fh "#call,Hz,unix,mode,grid,lat,lng,park,org\n";

for my $s (@$spots) {
    next unless ref $s eq 'HASH';

    my $call = $s->{activator} // next;
    my $freq = $s->{frequency} // next;
    my $mode = $s->{mode} // '';
    my $park = $s->{reference} // '';
    my $time = $s->{spotTime} // next;

    # Optional / unavailable in public API
    my $grid = '';
    my $lat  = 0;
    my $lng  = 0;

    # Parse timestamp: YYYY-MM-DDTHH:MM:SS
    my ($Y,$m,$d,$H,$M,$S) =
        $time =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/
        or next;

    my $epoch = timegm($S,$M,$H,$d,$m-1,$Y);

    # Frequency is kHz → Hz (string-safe)
    my $hz = int($freq * 1000);

    print $fh join(',',
        $call,
        $hz,
        $epoch,
        $mode,
        $grid,
        $lat,
        $lng,
        $park,
        'POTA'
    ), "\n";
}

close $fh;
rename $TMP, $OUT or die "Rename failed\n";

