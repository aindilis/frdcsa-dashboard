#!/usr/bin/perl -w

use Carp;
use strict;



sub MenuLabels
{
 return qw[~File ~Edit ~Search ~View];
}

sub SearchMenuItems
{
 my ($w) = @_;
 return [
    ['command'=>'~Find',          -command => [$w => 'FindPopUp']],
    ['command'=>'Find ~Next',     -command => [$w => 'FindSelectionNext']],
    ['command'=>'Find ~Previous', -command => [$w => 'FindSelectionPrevious']],
    ['command'=>'~Replace',       -command => [$w => 'FindAndReplacePopUp']]
   ];
}

sub EditMenuItems
{
 my ($w) = @_;
 my @items = ();
 foreach my $op ($w->clipEvents)
  {
   push(@items,['command' => "~$op", -command => [ $w => "clipboard$op"]]);
  }
 push(@items,
    '-',
    ['command'=>'Select All', -command   => [$w => 'selectAll']],
    ['command'=>'Unselect All', -command => [$w => 'unselectAll']],
  );
 return \@items;
}

sub ViewMenuItems
{
 my ($w) = @_;
 my $v;
 tie $v,'Tk::Configure',$w,'-wrap';
 return  [
    ['command'=>'Goto ~Line...', -command => [$w => 'GotoLineNumberPopUp']],
    ['command'=>'~Which Line?',  -command =>  [$w => 'WhatLineNumberPopUp']],
    ['cascade'=> 'Wrap', -tearoff => 0, -menuitems => [
      [radiobutton => 'Word', -variable => \$v, -value => 'word'],
      [radiobutton => 'Character', -variable => \$v, -value => 'char'],
      [radiobutton => 'None', -variable => \$v, -value => 'none'],
    ]],
  ];
}


# Backward compatibility
sub GetMenu
{
 carp((caller(0))[3]." is deprecated") if $^W;
 shift->menu
}


sub FileMenuItems
{
 my ($w) = @_;
 return [
   ["command"=>'~Open',    -command => [$w => 'FileLoadPopup']],
   ["command"=>'~Save',    -command => [$w => 'Save' ]],
   ["command"=>'Save ~As', -command => [$w => 'FileSaveAsPopup']],
   ["command"=>'~Include', -command => [$w => 'IncludeFilePopup']],
   ["command"=>'~Clear',   -command => [$w => 'ConfirmEmptyDocument']],
   "-",@{$w->SUPER::FileMenuItems}
  ]
}

sub EditMenuItems
{
 my ($w) = @_;

 return [
    ["command"=>'Undo', -command => [$w => 'undo']],
    ["command"=>'Redo', -command => [$w => 'redo']],
     "-",@{$w->SUPER::EditMenuItems}
  ];
}


my $menu_frame = $top->Frame->pack(-anchor=>'nw');

##############################################
##############################################
## now set up menu bar
##############################################
##############################################

my $menu = $textwindow->menu;
$top->configure(-menu => $menu);

##############################################
# help menu
##############################################
my $help_menu = $menu->cascade(-label=>'~Help', -tearoff => 0, -menuitems => [
         [Command => 'A~bout', -command => \&about_pop_up]
         ]);

##############################################
# debug menu
##############################################

if (0)
	{
	my $debug_menu = $menu->cascade(-label=>'debug', -underline=>0);


	$debug_menu->command(-label => 'Tag names', -underline=> 0 ,
		-command =>
		sub{
		my @tags = $textwindow->tagNames();
		print " @tags\n";

		foreach my $tag (@tags)
			{
			my @ranges = $textwindow->tagRanges($tag);
			print "tag: $tag  ranges: @ranges \n";
			}

		print "\n\n\n";
		my @marks = $textwindow->markNames;
		print " @marks \n";
		foreach my $mark (@marks)
			{
			my $mark_location = $textwindow->index($mark);
			print "$mark is at $mark_location\n";
			}


		print "\n\n\n";
		my @dump = $textwindow->dump ( '-tag', '1.0', '465.0' );
		print "@dump \n";

		print "\n\n\n";
		print "showing tops children:";
		my @children = $top->children();
		print "@children\n";

		foreach my $child (@children)
			{
			my $junk = ref($child);
			print "ref of $child is $junk \n";
			}

		my $overstrike = $textwindow->OverstrikeMode;
		print "Overstrike is $overstrike \n";

		$textwindow->dump_array($textwindow);
		});
	}

##############################################
# set the window to a normal size and set the minimum size
$top->minsize(30,1);
$top->geometry("80x24");

#############################################################################
#############################################################################
#############################################################################
#############################################################################




##############################################
## this line for debug
## $top->bind('<Key>', [sub{print "ARGS: @_\n";}, Ev('k'), Ev('K') ]  );

##########################################
## fill the text window with initial file.

if ($argcount)
	{
	if (-e $global_filename) # if it doesn't exist, make it empty
		{
		# it may be a big file, draw the window, and then load it
		# so that we know something is happening.
		$top->update;
		$textwindow->Load($global_filename);
		}
	}


##############################################
$textwindow->CallNextGUICallback;

MainLoop();
