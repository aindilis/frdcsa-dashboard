package Dashboard::Tab::UniLangFacilitator;

use base qw(Dashboard::Tab);

use PerlLib::EasyPersist;
use UniLang::Util::AgentRegistry;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyFrame AgentRegistry /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyFrame($args{Frame});
  $UniLang::Util::AgentRegistry::unilangoptions = "";
  $self->AgentRegistry(GetAgentRegistry());
}

sub Execute {
  my ($self,%args) = @_;
  my $scrollframe = $self->MyFrame->Frame;
  my $box = $scrollframe->Listbox
    (
     -relief => 'sunken',
     -width  => 40,
     -setgrid => 1,
    );
  foreach (sort keys %{$self->AgentRegistry}) {
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

  $buttons = $self->MyFrame->Frame();
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
}

1;
