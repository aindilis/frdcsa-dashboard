package Dashboard::TabManager;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyMainWindow MyNotebook MainMenu MyMenu Tabs TabInfo /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Tabs({});
  $self->TabInfo
    ({
      "Android" => {
		    Module => "AndroidClient",
		    Default => 0,
		   },
      "Documentation" => {
			  Module => "Documentation",
			  Default => 1,
			 },
      "SPSE" => {
		 Module => "SPSE",
		 Default => 1,
		},
      "Launcher" => {
		     Module => "Launcher",
		     Default => 1,
		    },
      "Facilitator" => {
			Module => "UniLangFacilitator",
			Default => 1,
		       },
      "CLEAR" => {
		  Module => "CLEAR",
		  Default => 1,
		 },
     });
}

sub Execute {
  my ($self,%args) = @_;
  $self->StartGUI(%args);
}

sub StartGUI {
  my ($self,%args) = @_;
  $self->MyMainWindow($args{MainWindow});
  $self->MainMenu($args{MainMenu});
  $self->MyNotebook($self->MyMainWindow->NoteBook());
  $self->MyMenu($self->MainMenu->Menubutton(-text => "Tabs"));
  foreach my $tabname (sort keys %{$self->TabInfo}) {
    my $open = 0;
    if ($self->TabInfo->{$tabname}->{Default}) {
      $self->StartTab
	(
	 Tabname => $tabname,
	);
      $open = 1;
    }
    $self->AddTabToTabMenu
      (
       Tabname => $tabname,
       Open => $open,
      );
  }
  $self->MyNotebook->pack(-expand => 1, -fill => "both");
}

sub StartTab {
  my ($self,%args) = @_;
  my $myframe = $self->MyNotebook->add($args{Tabname}, -label => $args{Tabname});
  my $modulename = "Dashboard::Tab::".$self->TabInfo->{$args{Tabname}}->{Module};
  # print Dumper({Modulename => $modulename});
  my $require = $modulename;
  $require =~ s/::/\//g;
  $require .= ".pm";
  my $fullrequire = "/var/lib/myfrdcsa/codebases/minor/frdcsa-dashboard/$require";
  if (! -f $fullrequire) {
    # print "ERROR, no <<<$fullrequire>>>\n";
    return;
  }
  require $fullrequire;

  my $newtab = eval "$modulename->new(Frame => \$myframe)";
  # print Dumper($@);
  $self->Tabs->{$args{Tabname}} = $newtab;
  if (defined $newtab) {
    $newtab->Execute();
  }
}

sub AddTabToTabMenu {
  my ($self,%args) = @_;
  my $open = $args{Open};
  $self->MyMenu->checkbutton(-label => $args{Tabname}, -variable => \$open);
}

1;
