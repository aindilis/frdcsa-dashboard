#!/usr/bin/perl -w

sub Hi {
  return "hi";
}

my $res = eval "Hi();";
print $res."\n";
