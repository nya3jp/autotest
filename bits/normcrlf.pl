#!/usr/bin/perl

binmode(STDIN);
$_=join('', <STDIN>);
s/\x0D\x0A|\0x0D|\0x0A/\x0A/sg;
print $_;

