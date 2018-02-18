#!/usr/bin/perl -w

use BOSS::Config;
use PerlLib::EasyPersist;
use UniLang::Util::AgentRegistry;

use Data::Dumper;
use Tk;

my $top1 = MainWindow->new
  (
   -title => "UniLang Facilitator",
   -height => 600,
   -width => 800,
  );

$UniLang::Util::AgentRegistry::unilangoptions = "";
my %AgentRegistry = %{GetAgentRegistry()};

sub Start {
  my %args = @_;
  my $menu = $top1->menu;
  $menu->add("cascade", -label => "Search");
  $top1->configure(-menu => $menu);

  my $scrollframe = $top1->Frame;
  my $box = $scrollframe->Listbox(
				  -relief => 'sunken',
				  -width  => 40,
				  -setgrid => 1,
				 );
  foreach (sort keys %AgentRegistry) {
    $box->insert('end', $_);
  }
  $box->bind('all', '<Control-c>' => \&exit);
  $box->bind('<Double-Button-1>' => sub {
	       my($listbox) = @_;
	       foreach (split ' ', $listbox->get('active')) {
		 print "$_\n";
	       }
	     });
  my $scroll = $scrollframe->Scrollbar(-command => ['yview', $box]);
  $box->configure(-yscrollcommand => ['set', $scroll]);
  $box->pack(-side => 'left', -fill => 'both', -expand => 1);
  $scroll->pack(-side => 'right', -fill => 'both');
  $scrollframe->pack;

  $buttons = $top1->Frame();
  $buttons->Button
    (
     -text => "Launch Agent",
     -command => sub { ExecuteCommand(); },
    )->pack(-side => "left");
  $buttons->Button
    (
     -text => "Cancel",
     -command => sub { exit(0); },
    )->pack(-side => "right");
  $buttons->pack;
  # $top1->Getimage(-file => "scater.gif")->pack();
  MainLoop;
}

Start();
