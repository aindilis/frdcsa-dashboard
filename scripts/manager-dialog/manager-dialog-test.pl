#!/usr/bin/perl -w

# take a script that normally uses manager::dialog, and have it
# interact with us through Tk

# has to be one that doesn't rely on the network

use Dashboard::Util::Dialog;

use Data::Dumper;

my $items = {
	     Basic => {
		       "This is a test" => 1,
		       "This is another test" => 1,
		      },
	     Medium => {
		       map {+"$_", 1} split /\n/, `ls -1 /home/andrewdo`,
		      },
	     Advanced => {
			 },
	    };

my $mode = Choose(keys %$items);
my @res = SubsetSelect(
	     Set => [keys %{$items->{$mode}}],
	     Selection => {},
	    );

my $res = Approve(Dumper(\@res));
my $res2 = QueryUser("Is this the right thing: $res");
print $res2."\n";
my $res3 = QueryUser("Is this the right thing: $res2");
print $res3."\n";
sleep 10;
