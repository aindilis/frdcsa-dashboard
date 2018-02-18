package Dashboard::Tab::Launcher::Program;

use BOSS::Config;
use PerlLib::EasyPersist;
use PerlLib::SwissArmyKnife;

use Data::Dumper;
use Tk;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Top1 Specifications Data Verbose /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Verbose($args{Verbose} || 0);
  $self->Specifications($args{Specifications});
  $self->Data({});
  if ($args{NoTopLevel}) {
    $self->Top1($args{MainWindow});
  } else {
    $self->Top1
      ($args{MainWindow}->Toplevel
       (
	-title => "FRDCSA Spec Test",
	-height => 600,
	-width => 800,
       ));
    $self->Top1->title( $args{Program} );
    my $menu = $self->Top1->menu;
    $menu->add("cascade", -label => "Search");
    $self->Top1->configure(-menu => $menu);
  }

  if (0) {
    $text = $self->Top1->Text(
			      -width => 25,
			      -height => 10,
			     );
    $text->insert("0.0", $specification);
    $text->pack();
  } else {
    # go ahead and add the image here
    my $splashframe = $self->Top1->Frame();
    my(@pl) = qw/-side left -padx .5m -pady .5m/;
    my $photofile = $self->GetPhotoForProgram(Program => $args{Program});
    print Dumper({Photo => $photofile}) if $self->Verbose;
    my $imagename = rand();
    $splashframe->Photo($imagename, -file => $photofile);
    $splashframe->Label(-image => $imagename)->pack(@pl);
    $splashframe->pack;
  }
  $self->ProcessSpecification
    (
     # Program => [keys %{$res->{Specifications}}]->[int(rand(scalar keys %{$res->{Specifications}}))],
     Program => $args{Program},
     Specification => $args{Specification},
     NoTopLevel => $args{NoTopLevel},
    );
}

sub ProcessSpecification {
  my ($self,%args) = @_;
  my $program = $args{Program};

  my $specification = $args{Specification} || $self->Specifications->{$program}->{Specification};
  print Dumper([$command, $specification]) if $self->Verbose;
  my $config = BOSS::Config->new
    (
     Spec => $specification,
     ConfFile => "",
    );
  my $conf = $config->CLIConfig;
  print Dumper($conf) if $self->Verbose;

  # print out all the options
  # Since left and right are taken, bottom will not work...
  # $frame = $self->Top1->Frame(-relief => 'flat');
  # $frame->pack(-side => 'top', -fill => 'y', -anchor => 'center');
  #   $menu = $self->Top1->Frame(-relief => 'raised', -borderwidth => '1');
  #   $menu->pack(-before => $frame, -side => 'top', -fill => 'x');
  #   $menu_file = $menu->Menubutton(-text => 'File', -underline => 0);
  #   $menu_file->command(-label => 'load ...', -command => sub { },
  # 		      -underline => 0);
  #   $menu_file->command(-label => 'Exit', -command => sub { }, -underline => 0);
  #   $menu_file->pack(-side => 'left');


  $options = $self->Top1->Frame();
  foreach my $arg (sort {$a->{ID} <=> $b->{ID}}  @{$conf->{_internal}->{args}}) {
    my $pd = $self->GetParameterDescription
      (
       Arg => $arg,
       Description => $description,
       Conf => $conf,
      );
    if ($pd->{Success}) {
      $data->{$pd->{Desc}} = {};
      if (! exists $arg->{args}) {
	$options->Checkbutton
	  (
	   -text => join(" ", (
			       # "(".$pd->{Desc}.")",
			       $pd->{Result},
			      )),
	   -command => sub { },
	  )->pack(-fill => "x", -anchor => 'left');
      } else {
	my $frame = $options->Frame(-relief => 'raised', -borderwidth => 2);
	my @items;
	foreach my $arg2 (@{$arg->{args}}) {
	  # 	  if ($arg2->isa('Getopt::Declare::ArrayArg')) {
	  # 	    my $frame2 = $frame->Frame();
	  # 	    my $nameLabel = $frame2->Label(-text => $arg2->{name}.':');
	  # 	    my $name = $frame2->Entry(
	  # 				       -relief       => 'sunken',
	  # 				       -borderwidth  => 2,
	  # 				       -textvariable => \$data->{$pd->{Desc}}->{$arg2->{name}},
	  # 				       -width        => 25,
	  # 				      );

	  # 	    $nameLabel->pack(-side => 'left');
	  # 	    $name->pack(-side => 'right');
	  # 	    $name->bind('<Return>' => [ $middle, 'color', Ev(['get'])]);
	  # 	    $frame2->pack;
	  # 	  } elsif () {

	  # 	  }
	  if ($arg2->isa('Getopt::Declare::ScalarArg')) {
	    my $frame2 = $frame->Frame();
	    my $nameLabel = $frame2->Label
	      (
	       -text => $arg2->{name}.':',
	       -state => 'disabled',
	      );
	    my $name = $frame2->Entry
	      (
	       -state => 'disabled',
	       -relief       => 'sunken',
	       -borderwidth  => 2,
	       -textvariable => \$data->{$pd->{Desc}}->{$arg2->{name}},
	       -width        => 25,
	      );
	    push @items, {
			  frame => $frame2,
			  nameLabel => $nameLabel,
			  name => $name,
			 };
	    $nameLabel->pack(-side => 'left');
	    $name->pack(-side => 'right');
	    $name->bind('<Return>' => [ $middle, 'color', Ev(['get'])]);
	  } else {
	    print Dumper({Huh => $arg2});
	  }
	}
	my $checkbutton = $frame->Checkbutton
	  (
	   -text => join(" ", (
			       # "(".$pd->{Desc}.")",
			       $pd->{Result},
			      )),
	   -command => sub {
	     foreach my $item (@items) {
	       if ($item->{name}->cget('-state') eq 'disabled') {
		 $item->{name}->configure(-state => "normal");
		 $item->{nameLabel}->configure(-state => "normal");
	       } else {
		 $item->{name}->configure(-state => "disabled");
		 $item->{nameLabel}->configure(-state => "disabled");
	       }
	     }
	   },
	  );
	$checkbutton->pack(-fill => "x");
	foreach my $item (@items) {
	  $item->{frame}->pack;
	}
	$frame->pack();
      }
    } else {
      print "HEY!\n";
    }
  }
  $options->pack;

  $buttons = $self->Top1->Frame();
  $buttons->Button
    (
     -text => "Defaults",
     -command => sub { },
    )->pack(-side => "left");
  $buttons->Button
    (
     -text => "Save Configuration",
     -command => sub { },
    )->pack(-side => "left");
  $buttons->Button
    (
     -text => "Documentation",
     -command => sub { system "mozilla -remote \"openURL(http://www.frdcsa.org)\""},
    )->pack(-side => "left");
  $buttons->Button
    (
     -text => "Execute",
     -command => sub { $self->ExecuteCommand(); },
    )->pack(-side => "left");
  $buttons->Button
    (
     -text => "Cancel",
     -command => sub { $self->Top1->destroy; },
    )->pack(-side => "right");
  $buttons->pack;
  # $self->Top1->Getimage(-file => "scater.gif")->pack();
  MainLoop unless $args{NoTopLevel};
}

sub GetParameterDescription {
  my ($self,%args) = @_;
  # See(\%args);
  foreach my $line (split /\n/, $args{Conf}->{_internal}->{usage}) {
    my $regex = $args{Arg}->{desc};
    See({
	 Regex => $regex,
	 Line => $line,
	}) if $self->Verbose;
    $regex =~ s/^\s+//;
    $regex =~ s/\s+$//;
    $regex =~ s/([^[:alpha:]])/\\$1/g;
    if ($line =~ /^\s*$regex\s+(.+?)\s*$/) {
      my $item = $1;
      return {
	      Success => 1,
	      Desc => $args{Arg}->{desc},
	      Result => $item,
	     };
    }
  }
  return {
	  Success => 0,
	 };
}

sub ExecuteCommand {
  my ($self,%args) = @_;
  # get all the options, and run them
  # print join(" ",@args)."\n";
  # iterate over all the frames contained here
  foreach my $child ($self->Top1->children) {
    print Dumper($child);
  }
}

sub GetPhotoForProgram {
  my ($self,%args) = @_;
  my $prog = $args{Program};
  my $res = `ls -al $prog`;
  chomp $res;
  foreach my $line (split /\n/, $res) {
    if ($line =~ / -> (.+)\s*$/) {
      my $symlink = $1;
      if ($symlink =~ q{/var/lib/myfrdcsa/codebases/(internal|minor)/([^\/]+)/.+}) {
	my $photofile = "/var/lib/myfrdcsa/codebases/$1/$2/frdcsa/project.gif";
	if (-f $photofile) {
	  return $photofile;
	}
	print Dumper({
		      Photofile => $photofile,
		      Symlink => $symlink,
		      Lin => $line,
		      Prog => $prog,
		      Res => $res,
		      }) if $self->Verbose;
      }
    }
  }
  return "/var/lib/myfrdcsa/codebases/internal/fweb/frdcsa/project.gif";
}

1;
