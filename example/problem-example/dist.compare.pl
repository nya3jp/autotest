#!/usr/bin/perl

use strict;

my ($AC, $PE, $WA, $RE, $TLE, $MLE, $OLE, $CE, $ISE, $CTLE, $OFE, $INVALID) = (0..11);
my @RESULT_STRINGS = ("Accepted",
                      "Presentation Error",
                      "Wrong Answer",
                      "Runtime Error",
                      "Time Limit Exceeded",
                      "Memory Limit Exceeded",
                      "Output Limit Exceeded",
                      "Compilation Error",
                      "Internal Server Error",
                      "Compilation Time Limit Exceeded",
                      "Output Format Error",
                      "Invalid Output");

if (@ARGV != 4) {
	print $ISE;
	die "usage: compare.pl infile outfile ansfile resfile";
}

my ($infile, $ansfile, $outfile, $resfile) = @ARGV;

unless (open(RES, "> $resfile")) {
    print $ISE;
    die("cannot open $resfile");
}


sub read_file {
    my ($filename) = @_;
    if (!open(FILE, "< $filename")) {
        print $ISE;
        die "can not open $filename";
    }
    my $capacity = 4*1024*1024;
    my $data = '';
    my $datalen = 0;
    while($datalen < $capacity) {
        my $readlen = sysread(FILE, $data, $capacity - $datalen, $datalen);
        last if ($readlen == 0);
        $datalen += $readlen;
    }
    my $tmp;
    if (sysread(FILE, $tmp, 1) != 0) {
        print $OLE;
        exit 0;
    }
    return $data;
}

my $indata = &read_file($infile);
my $ansdata = &read_file($ansfile);
my $outdata = &read_file($outfile);

sub wrong_answer {
    my ($reason) = @_;
    print $WA;
    print RES "$reason\n";
    exit 0;
}

if ($ansdata !~ m{^(-?\d+\.?\d*)\n$}s) {
    &wrong_answer('ansdata does not match RE ^(-?\d+\.?\d+?)\n$');
}
my ($ans) = ($1);

if ($outdata !~ m{^(-?\d+\.\d{5})\n$}s) {
    &wrong_answer('outdata does not match RE ^(-?\d+\.\d{5})\n$');
}
my ($out) = ($1);

my ($diff) = (abs($ans-$out));

my $delta = 1e-5;
unless ($diff <= $delta+1e-8) {
    &wrong_answer("diff = $diff");
}

print $AC;

exit 0;
