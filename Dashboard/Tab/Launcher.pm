package Dashboard::Tab::Launcher;

use base qw(Dashboard::Tab);

use Dashboard::Tab::Launcher::Program;
use MyFRDCSA;
use PerlLib::EasyPersist;
use Rival::PPI::_Util;

use Data::Dumper;
use File::Slurp;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyFrame MyEasyPersist Specifications /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyFrame($args{Frame});
  $self->MyEasyPersist
    (PerlLib::EasyPersist->new
     (
      Namespace => "frdcsa-dashboard",
      Expires => "1 month",
     ));

  my $res = $self->MyEasyPersist->CacheObj->get("specs");
  if (! defined $res) {
    $res = $self->BuildIndexOfAvailableSoftware();
    $self->MyEasyPersist->CacheObj->set("specs",$res,"1 month");
  }
  if ($res->{Success}) {
    $self->Specifications($res->{Specifications});
  } else {
    die "unable to get specifications\n";
  }
}

sub Execute {
  my ($self,%args) = @_;
  $self->StartTk
    (
     Specifications => $self->Specifications,
    );
}

sub StartTk {
  my ($self,%args) = @_;
  my $scrollframe = $self->MyFrame->Frame;
  my $box = $scrollframe->Listbox(
				  -relief => 'sunken',
				  -width  => 80,
				  -setgrid => 1,
				 );
  my @items = sort keys %{$args{Specifications}};
  # my @items = qw(One Two Three Four Five Six Seven
  # Eight Nine Ten Eleven Twelve);
  foreach (@items) {
    $box->insert('end', $_);
  }
  $box->bind('all', '<Control-c>' => \&exit);
  $box->bind('<Double-Button-1>' => sub {
	       my($listbox) = @_;
	       foreach (split ' ', $listbox->get('active')) {
		 $self->ProcessSpecification
		   (
		    Program => $_,
		    InvocationCommand => "",
		   );
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
     -text => "Cancel",
     -command => sub { $self->MyFrame->destroy; },
    )->pack();
  $buttons->pack;
  MainLoop;
}

sub BuildIndexOfAvailableSoftware {
  my ($self,%args) = @_;
  # list all scripts, and extract their options
  # list all modules and extract their options
  $specifications = {};
  my $commands =
    [
     "`boss list_modules`",
     "`boss list_scripts`",
    ];
  foreach my $command (@$commands) {
    my $res = $self->MyEasyPersist->Get
      (
       Command => $command,
      );
    # now take this data, and use it to parse the items with PPI
    if ($res->{Success}) {
      foreach my $file (split /\n/, $res->{Result}) {
	# correct the path
	if ($file !~ /^\// and $file =~ /\.pm$/i) {
	  $file = "/usr/share/perl5/".$file;
	}
	my $res2;
	if (-f $file) {
	  $res2 = $self->ExtractSpecificationInformation
	    (
	     File => $file,
	    );
	}
	if ($res2->{Success}) {
	  # okay add this to the system
	  $specifications->{$res2->{Result}->{InvocationCommand}}->{Specification} = $res2->{Result}->{Specification};
	  # okay now attempt to do something with this
	}
      }
    }
  }
  return {
	  Success => 1,
	  Specifications => $specifications,
	 };
}

sub ExtractSpecificationInformation {
  my ($self,%args) = @_;
  my $c = read_file($args{File});
  if ($c =~ /\$specification/) {
    print "<".$args{File}.">\n";
    my $doc = PPI::Document->new($args{File});
    # my $dumper = PPI::Dumper->new($doc);
    # $dumper->print;
    my $nodes = $doc->find
      (
       sub { $_[1]->isa('PPI::Statement') and
	       [$_[1]->children]->[0]->isa('PPI::Token::Symbol') and
		 [$_[1]->children]->[0]->symbol eq '$specification' }
      );
    foreach my $node (@$nodes) {
      my $res = ProcessVariables(Node => $node);
      if ($res->{Success}) {
	return {
		Success => 1,
		Result => {
			   Specification => NodeSerialize(Node => $res->{Result}->{RHSs}->[0]),
			   InvocationCommand => $args{File},
			  },
	       };
      }
    }
    return {
	    Success => 0,
	   };
  }
  return {
	  Success => 0,
	 };
}

sub ProcessSpecification {
  my ($self,%args) = @_;
  my $program = Dashboard::Tab::Launcher::Program->new
    (
     MainWindow => $self->MyFrame,
     InvocationCommand => $args{InvocationCommand},
     Program => $args{Program},
     Specifications => $self->Specifications,
    );
}

1;
