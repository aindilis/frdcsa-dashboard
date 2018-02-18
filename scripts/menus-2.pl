#!/usr/bin/perl -w

use Tk;

my $top = MainWindow->new();

my $text_frame = $top->Frame->pack
	(-anchor=>'nw', -expand=>'yes', -fill => 'both'); # autosizing

my $textwindow = $text_frame->Scrolled(
	'TextEdit',
	-exportselection => 'true',  # 'sel' tag is associated with selections
	# initial height, if it isnt 1, then autosizing fails
	# once window shrinks below height
	# and the line counters go off the screen.
	# seems to be a problem with the Tk::pack command;
	-height => 1,
	-background => 'white',
	-wrap=> 'none',
	-setgrid => 'true', # use this for autosizing
	-scrollbars =>'se')
	-> pack(-expand => 'yes' , -fill => 'both');	# autosizing

my $menu = $textwindow->menu;
$top->configure(-menu => $menu);

MainLoop;
