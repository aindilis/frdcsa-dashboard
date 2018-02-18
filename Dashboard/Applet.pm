package Dashboard::Applet;

use Manager::Misc::NotificationManager;
use MyFRDCSA qw(ConcatDir Dir);
use PerlLib::SwissArmyKnife;

use Gtk2;
use Gtk2::TrayIcon;
use IO::Handle;
use Tk;
use Tk::Menu;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Config MyMainWindow MainMenu MyTabManager Withdrawn
	MenuIsPosted GUIs MyWindows /

  ];

sub init {
  my ($self,%args) = @_;
  $specification = "
	-l			Log STDOUT and STDERR to the log file

	-u [<host> <port>]	Run as a UniLang agent

	-w			Require user input before exiting
	-W [<delay>]		Exit as soon as possible (with optional delay)
";
  $UNIVERSAL::systemdir = ConcatDir(Dir("minor codebases"),"dashboard");
  $self->Config(BOSS::Config->new
		(Spec => $specification,
		 ConfFile => ""));
  my $conf = $self->Config->CLIConfig;
  if ($conf->{'-l'}) {
    open OUTPUT, '>', "/home/justin/.config/frdcsa/frdcsa-applet/stdout.log" or die $!;
    open ERROR,  '>', "/home/justin/.config/frdcsa/frdcsa-applet/stderr.log"  or die $!;
    STDOUT->fdopen( \*OUTPUT, 'w' ) or die $!;
    STDERR->fdopen( \*ERROR,  'w' ) or die $!;
  }
  $self->Withdrawn(1);
  $self->MenuIsPosted(0);
  $self->MyMainWindow
    (
     MainWindow->new
     (
      -title => "FRDCSA Dashboard",
      -height => 100,
      -width => 100,
     ),
    );
  $UNIVERSAL::managerdialogtkwindow = $self->MyMainWindow;
  $self->MainMenu
    ($self->MyMainWindow->Menu
     (
      -tearoff => 0,
     ));
  $self->GUIs
    ({
      # "Akahige" => "",
      # "ALL" => "",
      "Bluetooth Manager" => "/var/lib/myfrdcsa/codebases/internal/manager/scripts/bluetooth-manager.pl",
      # "Broker" => "",
      "CHAP" => "/var/lib/myfrdcsa/codebases/minor/chap/chap",
      "Chess" => "uxterm /var/lib/myfrdcsa/codebases/minor/chap/scripts/chess",
      "Go" => "qgo",
      "Planeshift" => "/home/andrewdo/Media/software/games/Planeshift/0.5.8/0.5.8/PlaneShift/psclient",
      "CLEAR" => "/var/lib/myfrdcsa/codebases/internal/clear/cla -gu",
      "Critic Browser" => "/var/lib/myfrdcsa/codebases/minor/critic-browser/scripts/application-agent.pl",
      "Entertainment Center" => "/var/lib/myfrdcsa/codebases/minor/entertainment-center/ec",
      "FRDCSA Dashboard" => "/var/lib/myfrdcsa/codebases/minor/frdcsa-dashboard/frdcsa-dashboard",
      "Gourmet2" => "/var/lib/myfrdcsa/codebases/minor/gourmet2/gourmet2",
      "Job-Search Rapid Responder" => "/var/lib/myfrdcsa/codebases/minor/js-rapid-response/rapid-response -sa",
      "LocationLogic" => "/var/lib/myfrdcsa/codebases/minor/location-logic/location-logic-simulator.pl",
      "Media Library" => "/var/lib/myfrdcsa/codebases/minor/media-library/scripts/media-library-gui.pl",
      "Musical Notation" => "/var/lib/myfrdcsa/codebases/minor/musical-system/play-song",
      "Notification Manager" => sub {
	$self->ToggleWithdrawn
	  (
	   Item => "Notification Manager",
	  );
      },
      "Paperless Office" => "/var/lib/myfrdcsa/codebases/minor/paperless-office/paperless-office --gui",
      "Play Movie" => "play-movie.pl",
      "Sensor" => {
		   Type => "checkbutton",
		   CheckAction => sub {
		     system "/var/lib/myfrdcsa/codebases/internal/manager/scripts/audio-sensor.pl -r -f &";
		   },
		   UncheckAction => sub {
		     system "killall parec";
		   },
		  },
      "SPSE2" => "/var/lib/myfrdcsa/codebases/minor/spse/spse2",
      "Study" => "anki",
      # Some other ones, UniLang facilitator, Launcher
     });
  my $dismissstring = "Dismiss";
  my $quitstring = "Quit";
  my @menuitems1 = ($dismissstring, "Systems", "Actions", $quitstring);
  my @menuitems2 = sort keys %{$self->GUIs};
  foreach my $menuitem1 (@menuitems1) {
    if ($menuitem1 eq $quitstring) {
      $self->MainMenu->command
	(
	 -label => $menuitem1,
	 -command => sub {
	   $self->Exit();
	 },
	);
    } elsif ($menuitem1 eq $dismissstring) {
      $self->MainMenu->command
	(
	 -label => $menuitem1,
	 -command => sub {
	   return;
	 },
	);
    } elsif ($menuitem1 eq "Actions") {
      my $actionmenu = $self->MainMenu->cascade
	(
	 -label => "Actions",
	 -tearoff => 0,
	);
      $actionmenu->command
	(
	 -label => "Edit Source",
	 -command => sub {system "emacsclient.emacs22 /var/lib/myfrdcsa/codebases/minor/frdcsa-dashboard/Dashboard/Applet.pm &";},
	);
      $actionmenu->command
	(
	 -label => "Manager Init",
	 -command => sub {system "uxterm +lc -e \"/var/lib/myfrdcsa/codebases/internal/manager/manager --init\" &";},
	);
    } elsif ($menuitem1 eq "Systems") {
      my $systemmenu =  $self->MainMenu->cascade
	(
	 -label => 'Systems',
	 -tearoff => 0,
	);
      foreach my $menuitem2 (@menuitems2) {
	my $type;
	my $command;
	my $command2;
	my $ref = ref $self->GUIs->{$menuitem2};
	if ($ref eq "") {
	  $command = sub {system $self->GUIs->{$menuitem2}." &"};
	  $type = "command";
	} elsif ($ref eq "CODE") {
	  $command = sub {$self->GUIs->{$menuitem2}->();};
	  $type = "command";
	} elsif ($ref eq "HASH") {
	  my $entry = $self->GUIs->{$menuitem2};
	  $type = $entry->{Type} || "command";
	  $command = sub {

	  };
	}
	if ($type eq "command") {
	  $systemmenu->command
	    (
	     -label => $menuitem2,
	     -command => $command,
	    );
	} elsif ($type eq "checkbutton") {
	  my $tmp = 0;
	  $self->GUIs->{$menuitem2}->{Variable} = \$tmp;
	  $systemmenu->checkbutton
	    (
	     -label => $menuitem2,
	     -variable => $self->GUIs->{$menuitem2}->{Variable},
	     -command => sub {
	       # print "<".${$self->GUIs->{$menuitem2}->{Variable}}.">\n";
	       if (${$self->GUIs->{$menuitem2}->{Variable}}) {
		 $self->GUIs->{$menuitem2}->{CheckAction}->();
	       } else {
		 $self->GUIs->{$menuitem2}->{UncheckAction}->();
	       }
	     },
	    );
	}
      }
    }
  }

  Gtk2->init;
  my $iconfile = "/var/lib/myfrdcsa/codebases/minor/frdcsa-dashboard/data/frdcsa-icon.png";
  my $icon = Gtk2::Image->new_from_file($iconfile);
  my $eventbox = Gtk2::EventBox->new;
  $eventbox->add( $icon );
  my $trayicon = Gtk2::TrayIcon->new( 'Info' );
  $trayicon->add( $eventbox );
  $trayicon->show_all;
  $eventbox->signal_connect
    (
     'button_press_event',
     sub {
       my ($eventbox,$eventbutton) = @_;
       # figure out which type of button this is, if it is right
       # button, do menu, else, toggle withdrawn
       if ($eventbutton->button == 1) {
	 $self->ToggleWithdrawn
	   (
	    Item => "Notification Manager",
	   );
       } elsif ($eventbutton->button == 2) {
       } elsif ($eventbutton->button == 3) {
	 if ($self->MenuIsPosted) {
	   $self->MainMenu->unpost();
	   # $self->MenuIsPosted(0);
	 } else {
	   my ($x,$y) = $eventbox->window->get_origin;
	   $x += $eventbutton->x;
	   $y += $eventbutton->y;
	   $self->MainMenu->post($x, $y);
	   # $self->MenuIsPosted(1);
	 }
       }
     },
    );
  my $tktimer = $self->MyMainWindow->repeat
    (
     10,
     sub {
       Gtk2->main_iteration while Gtk2->events_pending;
     },
    );
  $self->MyMainWindow->withdraw();
  $self->MyWindows({});
  $self->MyWindows->{"Notification Manager"} = Manager::Misc::NotificationManager->new
    (
     MainWindow => $self->MyMainWindow->Toplevel,
     Applet => $self,
    );
  $self->ToggleWithdrawn(Item => "Notification Manager");
  # $self->MyWindows->{"Notification Manager"}->Execute();
}

sub Execute {
  my ($self,%args) = @_;
  $self->MyWindows->{"Notification Manager"}->MyMainLoop();
}

sub ToggleWithdrawn {
  my ($self,%args) = @_;
  my $class;
  if ((! defined $args{Item}) or (! exists $self->MyWindows->{$args{Item}})) {
    $class = $self;
  } else {
    $class = $self->MyWindows->{$args{Item}};
  }
  if ($class->Withdrawn) {
    $class->MyMainWindow->deiconify();
    $class->MyMainWindow->raise();
    $class->Withdrawn(0);
  } else {
    $class->MyMainWindow->withdraw();
    $class->Withdrawn(1);
  }
}

sub Exit {
  my ($self,%args) = @_;
  if (1) {
    my $dialog = $UNIVERSAL::managerdialogtkwindow->Dialog
      (
       -text => "Please Choose",
       -buttons => [qw/Exit Restart Cancel/],
      );
    my $res = $dialog->Show;
    if ($res eq "Exit") {
      exit(0);
    } elsif ($res eq "Restart") {
      # kill it and start a new one
      $self->Restart();
    } elsif ($res eq "Cancel") {
      # do nothing
    }
  } else {
    if (Approve("Exit FRDCSA Applet?")) {
      exit(0);
    }
  }
}

sub Restart {
  my ($self,%args) = @_;
  system "(sleep 1; /var/lib/myfrdcsa/codebases/minor/frdcsa-dashboard/frdcsa-applet &)";
  KillProcesses
    (
     Process => "frdcsa-applet",
     AutoApprove => 1,
    );
  KillProcesses
    (
     Process => "/usr/bin/perl -w ./frdcsa-applet",
     AutoApprove => 1,
    );
  exit(0);
  die();
}

1;


# Cognitive Aid
# 	"Critic Browser"
# 	"LocationLogic"
# 	"Notification Manager"
# 	"FRDCSA Dashboard"
# 	"SPSE2"
# Software Conglomeration
# Office
# 	"Job-Search Rapid Responder"
# 	"Paperless Office"
# Health
# 	"Gourmet2"
# Recreation
# 	"Musical Notation"
# 	"Media Library"
# 	"Entertainment Center"
# 	"Chess"
# 	"Play Movie"
# Ethics
# POSI

# Education
# 	"CLEAR"
# AI
# 	"CHAP"
# Security
# 	"Bluetooth Manager"
