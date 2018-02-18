package Dashboard::Util::Dialog;

use Data::Dumper;
use Tk;
use Tk::Checkbutton;
use Tk::Dialog;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw (QueryUser ComplexQueryUser Verify Approve ApproveStrongly ApproveCommand Choose ChooseSpecial
	      EasyQueryUser PrintList Message ApproveCommands
	      ChooseHybrid ChooseOrCreateNew SubsetSelect FamilySelect ChooseByProcessor Continue);

my $tkwindow;
if (exists $ENV{FRDCSA_DASHBOARD} and $ENV{FRDCSA_DASHBOARD} eq "enabled") {
  $tkwindow = MainWindow->new(-title => join(" ",$0, @ARGV));
}
my $continueloop;

sub EasyQueryUser {
  my $entry;
  if (defined $tkwindow) {
    # open up a text window
    # MainLoop;
  } else {
    chomp ($entry = <STDIN>);
    return $entry;
  }
}

sub QueryUser {
  my ($contents) = (shift || "");
  if (defined $tkwindow) {
    my $top1 = $tkwindow->Toplevel();
    my $searchtext = "";
    my $queryframe = $top1->Frame();
    my $label = $queryframe->Label(-text => $contents);
    $label->pack();
    my $query = $queryframe->Entry
      (
       -relief       => 'sunken',
       -borderwidth  => 2,
       -textvariable => \$searchtext,
       -width        => 70,
      )->pack(-side => 'left');
    $queryframe->Button
      (
       -text => "Submit",
       -command => sub {
	 $continueloop = 0;
       },
      )->pack(-side => 'right');
    $queryframe->pack;
    MyMainLoop();
    $top1->destroy();
    DoOneEvent(0);
    return $searchtext;
  } else {
    print "$contents\n> ";
    my $result = <STDIN>;
    while ($result =~ /^$/) {
      $result = <STDIN>;
    }
    chomp $result;
    return $result;
  }
}

sub ComplexQueryUser {
  my %args = @_;
  my $prompt = $args{Prompt} || "> ";
  my ($contents) = $args{Query}."\n" || "";
  print "$contents$prompt";
  my $result = <STDIN>;
  while ($result =~ /^$/) {
    $result = <STDIN>;
  }
  chomp $result;
  return $result;
}

sub Verify {
  my ($contents) = (shift || "Is this correct?");
  my $result = QueryUser($contents);
  while ($result !~ /^[yY|nN]$/) {
    $result = QueryUser("Please respond: [yYnN]");
  }
  return ($result =~ /^[yY]$/);
}

sub ApproveCommand {
  my $command = shift;
  print "$command\n";
  if (Approve("Execute this command? ")) {
    system $command;
    return 1;
  }
  return;
}

sub ApproveCommands {
  my %args = @_;
  if ((defined $args{Method}) && ($args{Method} =~ /parallel/i)) {
    foreach $command (@{$args{Commands}}) {
      Message(Message => $command);
    }
    # bug: use proof theoretic fail conditions here instead
    if ($args{AutoApprove} || Approve("Execute these commands? ")) {
      foreach my $command (@{$args{Commands}}) {
	system $command if ! $args{Simulate};
      }
      return 1;
    } else {
      return 0;
    }
  } else {
    my $outcome = 0;
    foreach $command (@{$args{Commands}}) {
      if ($args{AutoApprove}) {
	system $command;
	++$outcome;
      } elsif (ApproveCommand($command)) {
	++$outcome;
      }
    }
    return $outcome;
  }
}

sub Approve {
  if (defined $tkwindow) {
    my $dialog = $tkwindow->Dialog
      (
       -text => shift || "Is this correct?",
       -buttons => [qw/Yes No/],
      );
    my $res = $dialog->Show;
    if ($res eq "Yes") {
      return 1;
    }
    return 0;
  } else {
    my $message = shift || "Is this correct? ([yY]|[nN])\n";
    $message =~ s/((\?)?)[\s]*$/$1: /;
    print $message;
    my $antwort = <STDIN>;
    chomp $antwort;
    if ($antwort =~ /^[yY]([eE][sS])?$/) {
      return 1;
    }
    return 0;
  }
}

sub ApproveStrongly {
  my $message = shift || "Is this correct? (yes|no)\n";
  $message =~ s/((\?)?)[\s]*$/$1: /;
  print "$message\n";
  my $antwort = <STDIN>;
  chomp $antwort;
  if ($antwort =~ /^(yes|no)$/i) {
    return 1;
  }
  return 0;
}

sub Choose {
  my @list = @_;
  if (defined $tkwindow) {
    my $dialog = $tkwindow->Dialog
      (
       -text => "Please Choose",
       -buttons => \@list,
      );
    return $dialog->Show;
  } else {
    my $i = 0;
    if (!@list) {
      return;
    } elsif (@list == 1) {
      print "<Chose:".$list[0].">\n";
      return $list[0];
    } else {
      foreach my $item (@list) {
	print "$i) $item\n";
	++$i;
      }
      my $response;
      while (defined ($response = <STDIN>) and ($response !~ /^\d+$/)) {
      }
      chomp $response;
      return $list[$response];
    }
  }
}

sub ChooseSpecial {
  my %args = @_;
  my @list = @{$args{List}};
  if (!@list) {
    return;
  } elsif (@list == 1) {
    print "<Chose:".$list[0].">\n";
    return $list[0];
  } else {
    print PrintList(List => \@list,
		    Format => $args{Format});
    my $response;
    while (defined ($response = <STDIN>) and ($response !~ /^\d+$/)) {
    }
    chomp $response;
    return $list[$response];
  }
}

sub ChooseHybrid {
  my %args = @_;
  my @list = @{$args{List}};
  if (!@list) {
    return;
  } else {
    print PrintList(List => \@list,
		    Format => $args{Format});
    my $response;
    while (defined ($response = <STDIN>) and ($response =~ /^$/)) {
    }
    chomp $response;
    if ($response =~ /^\d+$/) {
      return ($list[$response],"match");
    } else {
      return ($response,"new");
    }
  }
}

sub ChooseReadkey {
  use Term::ReadKey;
  ReadMode('cbreak');
  if (defined ($char = ReadKey(-1)) ) {
    return $char;
  }
  ReadMode('normal');
}

sub PrintList {
  my %args = @_;
  my @list = @{$args{List}};
  my $format = $args{Format};
  my $result = "";
  my $i = 0;
  foreach my $item (@list) {
    if ($format eq "multiple") {
      $result .= "$i) $item\n";
    } elsif ($format eq "single") {
      $result .= "<$i:$item> ";
    } elsif ($format eq "simple") {
      $result .= "$item ";
    }
    ++$i;
  }
  return $result;
}

sub Message {
  my %args = @_;
  chomp $args{Message};
  print $args{Message}."\n";
}

sub ChooseOrCreateNew {
  my %args = @_;
  my @list = @{$args{List}};
  unshift @list, "<Other>";
  unshift @list, "<Cancel>";
  my $result = Choose(@list);
  if ($result =~ /^<Cancel>$/) {
    return;
  } elsif ($result =~ /^<Other>$/) {
    return QueryUser("Please enter your choice");
  } else {
    return $result;
  }
}

sub PrintSelect {
  my (%args) = (@_);
  my @options = @{$args{Options}};
  my $selection = $args{Selection};
  my $i = $args{MenuOffset};
  my $nowrap = $args{NoAllowWrap};
  if ($nowrap) {
    foreach my $i (0..$#options) {
      my $option = $options[$i];
      chomp $option;
      if (defined $selection->{$i}) {
	print "* ";
      } else {
	print "  ";
      }
      print "$i) ".$option.
	(($args{Desc} and exists $args{Desc}->{$option}) ? "\t".$args{Desc}->{$option} : "")."\n";
      # print "$i) ".$option. "\n";
      $i = $i + 1;
    }
  } else {
    # figure out our viewport and use that, normally it is 180x67
    my ($width, $height) = (100,30);
    # figure out how many wraps we have to do
    my $items = scalar @options;
    my $rows = int($items / $height) + 1;
    my $rowwidth = $width / $rows;
    my $margin = $rowwidth - 1;
    my $j = 0;
    my $k = 0;
    my $line = {};

    foreach my $i (0..$#options) {
      my $option = $options[$i];
      chomp $option;
      $line->{$j}->{$k} = "";
      if (defined $selection->{$i}) {
	$line->{$j}->{$k} .= "* ";
      } else {
	$line->{$j}->{$k} .= "  ";
      }
      $line->{$j}->{$k} .= "$i) ".$option.
	(($args{Desc} and exists $args{Desc}->{$option}) ? "\t".$args{Desc}->{$option} : "");
      # print "$i) ".$option. "\n";
      $i = $i + 1;
      ++$j;
      if ($j >= $height) {
	$j = 0;
	++$k;
      }
    }
    foreach my $j (sort {$a <=> $b} keys %{$line}) {
      my @items;
      foreach my $k (sort {$a <=> $b}  keys %{$line->{$j}}) {
	my @item = ($line->{$j}->{$k});
	push @items, substr(eval "sprintf(\"\%-${margin}s\",\@item)",0,$margin);
      }
      print join(" ",@items)."\n";
    }
  }
}

sub SubsetSelect {
  my (%args) = (@_);
  if (defined $tkwindow) {
    my $top1 = $tkwindow->Toplevel();
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

    $scrollframe = $top1->Frame;
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
    my $buttonframe = $top1->Frame;
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
       -command => sub { $top1->destroy(); },
      )->pack(-side => "left");
    $buttonframe->pack;
    MyMainLoop();
    $top1->destroy();
    DoOneEvent(0);
    return @$ourresults;
  } else {
    my @options;
    my $map = {};
    if ($args{Processor}) {
      @options = map &{$args{Processor}},@{$args{Set}};
    } else {
      @options = @{$args{Set}};
    }
    my $type = $args{Type};
    my $prompt = $args{Prompt} || "> ";
    if (scalar @options > 0) {
      unshift @options, "Finished";
      my %selection = ();
      if ($args{Selection}) {
	%tmp = %{$args{Selection}};
	foreach my $i (1..($#options + 1)) {
	  if (exists $tmp{$options[$i]}) {
	    $selection{$i} = 1;
	  }
	}
      }
      while (1) {
	PrintSelect
	  (Options => \@options,
	   Selection => \%selection,
	   MenuOffset => $args{MenuOffset} || 0,
	   NoAllowWrap => $args{NoAllowWrap},
	   Desc => $args{Desc});
	print $prompt;
	my $ans = <STDIN>;
	my $query;
	chomp $ans;
	if ($ans ne "") {
	  if ($ans) {
	    # go ahead and parse the language
	    foreach my $a (split /\s*,\s*/, $ans) {
	      my $method = "toggle";
	      if ($a =~ /^s(.*)/) {
		$a = $1;
		$method = "select";
	      } elsif ($a =~ /^d(.*)/) {
		$a = $1;
		$method = "deselect";
	      } elsif ($a =~ /^o(.*)/) {
		%selection = ();
		$a = $1;
		$method = "select-only";
	      } elsif ($a =~ /^q(.*)/) {
		$query = $1;
		$method = "search";
		$a = "0-".$#options;
	      }
	      my $start = $a;
	      my $end = $a;
	      if ($a =~ /^\s*(\d+)\s*-\s*(\d+)\s*$/) {
		$start = $1;
		$end = $2;
	      }
	      for (my $i = $start; $i <= $end; ++$i) {
		print "($i)\n";
		if ($method eq "toggle") {
		  if (defined $selection{$i}) {
		    delete $selection{$i};
		  } else {
		    $selection{$i} = 1;
		  }
		} elsif ($method eq "deselect") {
		  if (defined $selection{$i}) {
		    delete $selection{$i};
		  }
		} elsif ($method eq "select" or $method eq "select-only") {
		  $selection{$i} = 1;
		} elsif ($method eq "search") {
		  if ($options[$i] =~ /$query/) {
		    if (defined $selection{$i}) {
		      delete $selection{$i};
		    } else {
		      $selection{$i} = 1;
		    }
		  }
		}
	      }
	    }
	  } else {
	    if (defined $type and $type eq "int") {
	      my @retvals;
	      my $i = $args{MenuOffset} || 0;
	      foreach my $i (0..$#options) {
		if ($selection{$i}) {
		  push @retvals, $i - 1;
		}
		++$i;
	      }
	      return @retvals;
	    } else {
	      my @retvals;
	      my $i = $args{MenuOffset} || 0;
	      foreach my $i (0..$#options) {
		if ($selection{$i}) {
		  push @retvals, $args{Set}->[$i - 1];
		  # print Dumper($args{Set}->[$i - 1]);
		}
		++$i;
	      }
	      return @retvals;
	    }
	  }
	}
      }
    } else {
      return;
    }
  }
}

sub FamilySelect {
  my (%args) = (@_);
  # let's just do any easy one
  print "Family Select\n";
  print Dumper($args{Selection});
  my @subsets;
  do {
    push @subsets,
      [
       SubsetSelect
       (
	Set => $args{Set},
	Selection => $args{Selection},
	NoAllowWrap => $args{NoAllowWrap},
       )
      ];
  } while (! Approve("Finished Selecting Subsets? "));
  return @subsets;
}

# should write sublist select?

sub ChooseByProcessor {
  my (%args) = @_;
  my @entries = ("_Cancel");
  push @entries, map &{$args{Processor}}, @{$args{Values}};
  my $entry = Choose(@entries);
  my @matches;
  foreach my $v (@{$args{Values}}) {
    my @t = map &{$args{Processor}},($v);
    if ($t[0] eq $entry) {
    # if ($args{Processor}->($v) eq $entry) {
      push @matches, $v;
    }
  }
  return \@matches;
}

sub Continue {
  my (%args) = @_;
  if (! Approve("Continue?")) {
    &{$args{Result}};
  }
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

1;



# package Survivor::Dialog;

# # Depends: festival sphinx2-bin libclass-methodmaker-perl

# use Class::MethodMaker
#   new_with_init => 'new',
#   get_set       => [ qw / STTEngine TTSEngine / ];

# sub init {
#   my ($self,%ARGS) = (shift,@_);

#   # init STT engine
#   my $sstengine;
#   open($sttengine,"/usr/bin/sphinx2-demo |") or
#     die "Can't open Speech-To-Text engine.\n";
#   $self->STTEngine($sttengine);

#   # init TTS engine
#   my $ttsengine;
#   open($ttsengine,"| festival --pipe") or
#     die "Can't open Text-To-Speech engine.\n";
#   $self->TTSEngine($ttsengine);
# }

# my $state = 0;
# my $pass;
# print "[initializing]\n";
# sleep 20;
# system "festival ";
# while ($line = <FILE>) {
#   chomp $line;
#   if ($line =~ /\[initializing\]/) {
#     $state = 1;
#     print "[initialized]\n";
#   } elsif ($state == 1) {
#     if ($line =~ /(one|what)/) {
#       SayText("Roger, affirmative.");
#     } elsif ($line =~ /(two|do)/) {
#       SayText("Roger, negative.");
#     }
#     print "$line\n";
#   }
# }

# sub YesNoQuestion {
#   my ($self,$text) = (shift,shift);
#   my $response = $self->Ask($text);
#   if ($response =~ /yes/i) {
#     $self->Say("Roger, affirmative");
#     return 1;
#   } elsif ($response =~ /no/i) {
#     $self->Say("Roger, negative");
#     return 0;
#   }
# }

# sub Question {
#   my ($self,$text) = (shift,shift);
#   $self->Say($text);
#   return $self->Hear();
# }

# sub Say {
#   my ($self,$text) = (shift,shift);
#   print $self->TTSEngine $text;
# }

# sub Hear {

# }

# 1;
