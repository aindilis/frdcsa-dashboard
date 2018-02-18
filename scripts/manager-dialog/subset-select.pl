#!/usr/bin/perl -w

use Data::Dumper;
use Tk;
use Tk::Checkbutton;
# Manager::Dialog

my $tkwindow = MainWindow->new
  (
   -title => "Test Response",
   -height => 600,
   -width => 800,
  );

my $continueloop;

sub SubsetSelect {
  my %args = @_;
  my $ourresults;
  my $scrollframe;
  my @availableargs =
    (
     "Desc",
     "MenuOffset",
     "NoAllowWrap",
     "Processor",
     "Prompt",
     "Selection",
     "Set",
     "Type",
    );

  $scrollframe = $tkwindow->Frame;
  foreach my $item (@{$args{Set}}) {
    my $button = $scrollframe->Checkbutton
      (
       -text => $item,
      );
    $button->pack(-side => "top");
    if (exists $args{Selection}->{$item}) {
      $button->{Value} = 1;
    }
  }
  $scrollframe->pack;
  my $buttonframe = $tkwindow->Frame;
  $buttonframe->Button
    (
     -text => "Select",
     -command => sub {
       my @results;
       foreach my $child ($scrollframe->children) {
	 if (defined $child->{'Value'} and $child->{'Value'}) {
	   push @results, $child->cget('-text');
	 }
       }
       $continueloop = 0;
       $ourresults = \@results;
     },
    )->pack(-side => "left");
  $buttonframe->Button
    (
     -text => "Cancel",
     -command => sub { $tkwindow->DESTROY },
    )->pack(-side => "left");
  $buttonframe->pack;
  MyMainLoop();
  return @$ourresults;
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

print Dumper
  (SubsetSelect
   (
    Set => [1..25],
    Selection => {
		  1 => 1,
		  10 => 1,
		  12 => 1,
		  15 => 1,
		  19 => 1,
		 },
   ));
