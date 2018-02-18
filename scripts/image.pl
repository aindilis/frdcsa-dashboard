#!/usr/bin/perl -w

use Data::Dumper;
use Tk;

my $TOP = MainWindow->new
  (
   -title => "Image Load Test",
   -height => 600,
   -width => 800,
  );

my(@pl) = qw/-side top -padx .5m -pady .5m/;
$TOP->Photo('image1a', -file => "/var/lib/myfrdcsa/codebases/minor/frdcsa-dashboard/data/scater.gif");
$TOP->Label(-image => 'image1a')->pack(@pl);

MainLoop;
