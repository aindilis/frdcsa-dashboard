#!/usr/bin/perl -w

use Data::Dumper;
use Tk;

# Manager::Dialog

my $tkwindow = MainWindow->new
  (
   -title => "Test Response",
   -height => 600,
   -width => 800,
  );

my $continueloop;

sub QueryUser {
  my $contents = shift || "";
  my $top1 = $tkwindow->Toplevel();
  my $queryframe = $top1->Frame();
  $label = $queryframe->Label(-text => $contents);
  $label->pack();
  my $searchtext;
  my $query = $queryframe->Entry
    (
     -relief       => 'sunken',
     -borderwidth  => 2,
     -textvariable => \$searchtext,
     -width        => 70,
    )->pack(-side => 'left');
  $queryframe->Button
    (
     -text => "Submit",
     -command => sub {
       $continueloop = 0;
     },
    )->pack(-side => 'right');
  $queryframe->pack;
  MyMainLoop();
  $continueloop = 1;
  return $searchtext;
}

sub MyMainLoop
{
 unless ($inMainLoop)
  {
   local $inMainLoop = 1;
   $continueloop = 1;
   while ($continueloop)
    {
     DoOneEvent(0);
    }
  }
}

print Dumper(QueryUser("how is this?"));
