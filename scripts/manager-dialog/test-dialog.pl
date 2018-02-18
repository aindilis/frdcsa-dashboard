#!/usr/bin/perl -w

use Tk;
use Tk::Dialog;

my $mw = MainWindow->new
  (
   -title => "Dialog Test",
   -height => 600,
   -width => 800,
  );

my $dialog = $mw->Dialog
  (
   -text => "Save File?",
   -default_button => "This",
   -buttons => [qw/This That The Other Thing/],
  );

$answer = $dialog->Show;
MainLoop;
