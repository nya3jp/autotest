#!/usr/bin/perl

use Time::HiRes qw(gettimeofday tv_interval);
use POSIX qw(WIFEXITED WEXITSTATUS WIFSIGNALED WTERMSIG SIGTERM);

use strict;

my $sec = shift @ARGV;

die "timelimit must be > 0" if $sec < 1;

my $t0 = [gettimeofday];

my $pid = fork;
die "$!" unless defined $pid;

if($pid == 0){
  exec @ARGV;
  die "$! : $ARGV[0]";
}

my $elapsed;
{
  local $SIG{ALRM} = sub {kill 'TERM', $pid};
  alarm $sec;
  wait;
  $elapsed = tv_interval($t0);
  alarm 0;
}

my $retval = 255;
if(WIFEXITED($?)){
  $retval = WEXITSTATUS($?);
}elsif(WIFSIGNALED($?)){
  my $sig = WTERMSIG($?);
  $retval = 128 + $sig;
}

printf STDERR "%.2f\n", $elapsed;

exit $retval;
