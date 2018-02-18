#!/usr/bin/perl -w

use BOSS::Config;
use PerlLib::EasyPersist;

use Data::Dumper;
use Tk;

my $top1 = MainWindow->new
  (
   -title => "FRDCSA Spec Test",
   -height => 600,
   -width => 800,
  );

my $persister = PerlLib::EasyPersist->new
  (
   Namespace => "frdcsa-dashboard",
   Expires => "1 month",
  );

my $res = $persister->CacheObj->get("specs");

die unless $res->{Success};
my $specifications = $res->{Specifications};

# print Dumper($specifications);

ProcessSpecification
  (
   Module => [keys %{$res->{Specifications}}]->[int(rand(scalar keys %{$res->{Specifications}}))],
  );

my $data = {};

sub ProcessSpecification {
  my %args = @_;
  my $module = $args{Module};
  my $specification = $specifications->{$module}->{Specification};
  print Dumper($specification);
  # print Dumper([$command, $specification]);
  my $config = BOSS::Config->new
    (
     Spec => $specification,
     ConfFile => "",
    );
  my $conf = $config->CLIConfig;
  print Dumper($conf);
  # print out all the options

  # Since left and right are taken, bottom will not work...

  $frame = $top1->Frame(-relief => 'flat');
  $frame->pack(-side => 'top', -fill => 'y', -anchor => 'center');

  $menu = $top1->Frame(-relief => 'raised', -borderwidth => '1');
  $menu->pack(-before => $frame, -side => 'top', -fill => 'x');

  $menu_file = $menu->Menubutton(-text => 'File', -underline => 0);
  $menu_file->command(-label => 'load ...', -command => sub { },
		      -underline => 0);
  $menu_file->command(-label => 'Exit', -command => sub { }, -underline => 0);
  $menu_file->pack(-side => 'left');

  $top1->title( "$module" );

  $text = $top1->Text;
  $text->insert("0.0", $specification);
  $text->pack();

  $options = $top1->Frame();
  foreach my $arg (sort {$a->{ID} <=> $b->{ID}}  @{$conf->{_internal}->{args}}) {
    my $pd = GetParameterDescription
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
	  )->pack(-fill => "x");
      } else {
	my $frame = $options->Frame(-relief => 'raised', -borderwidth => 2);
	$frame->Checkbutton
	  (
	   -text => join(" ", (
			       # "(".$pd->{Desc}.")",
			       $pd->{Result},
			      )),
	   -command => sub {
	     # enable the text window
	   },
	  )->pack(-fill => "x");
	foreach my $arg2 (@{$arg->{args}}) {
# 	  if ($arg2->isa('Getopt::Declare::ArrayArg')) {
# 	    my $frame2 = $frame->Frame();
# 	    my $nameLabel = $frame2->Label(-text => $arg2->{name}.':');
# 	    my $name = $frame2->Entry(
# 				       -relief       => 'sunken',
# 				       -borderwidth  => 2,
# 				       -textvariable => \$data->{$pd->{Desc}}->{$arg2->{name}},
# 				       -width        => 10,
# 				       -height       => 5,
# 				      );

# 	    $nameLabel->pack(-side => 'left');
# 	    $name->pack(-side => 'right');
# 	    $name->bind('<Return>' => [ $middle, 'color', Ev(['get'])]);
# 	    $frame2->pack;
# 	  } elsif () {

# 	  }
	  if ($arg2->isa('Getopt::Declare::ScalarArg')) {
	    my $frame2 = $frame->Frame();
	    my $nameLabel = $frame2->Label(-text => $arg2->{name}.':');
	    my $name = $frame2->Entry(
				       -relief       => 'sunken',
				       -borderwidth  => 2,
				       -textvariable => \$data->{$pd->{Desc}}->{$arg2->{name}},
				       -width        => 10,
				      );

	    $nameLabel->pack(-side => 'left');
	    $name->pack(-side => 'right');
	    $name->bind('<Return>' => [ $middle, 'color', Ev(['get'])]);
	    $frame2->pack;
	  } else {
	    print Dumper($arg2);
	  }
	}
	$frame->pack();
      }
    } else {
      print "HEY!\n";
    }
  }
  $options->pack;

  $buttons = $top1->Frame();
  $buttons->Button
    (
     -text => "Execute",
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

sub GetParameterDescription {
  my %args = @_;
  foreach my $line (split /\n/, $args{Conf}->{_internal}->{usage}) {
    my $regex = $args{Arg}->{desc};
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
  # get all the options, and run them
  # print join(" ",@args)."\n";
}
