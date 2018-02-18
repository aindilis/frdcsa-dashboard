package Dashboard::Tab::Documentation;

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
}

sub Execute {
  my ($self,%args) = @_;
  my $splashframe = $self->MyFrame->Frame();

  my(@pl) = qw/-side left -padx .5m -pady .5m/;
  $splashframe->Photo(
		      'image1',
		      -file => "/var/lib/myfrdcsa/codebases/minor/frdcsa-dashboard/data/scater.gif",
		     );
  $splashframe->Label(-image => 'image1')->pack(@pl);
  $splashframe->pack;

  my $searchframe = $self->MyFrame->Frame();
  my $searchtext = "Where is the knowledge base of common problems and their solutions?";
  my $search = $searchframe->Entry
    (
     -relief       => 'sunken',
     -borderwidth  => 2,
     -textvariable => \$searchtext,
     -width        => 70,
    )->pack(-side => 'left');
  $searchframe->Button
    (
     -text => "Ask",
     -command => sub { },
    )->pack(-side => 'right');
  $searchframe->pack;

  $self->MyFrame->pack;
}

1;
