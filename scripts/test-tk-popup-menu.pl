#!/usr/bin/perl

use Tk;
use Tk::Menu;

# Create main window.
$mw = MainWindow->new();

# Create menu.
$menu = $mw->Menu();

# Add items to menu.
$menu->add('command', -label => 'One', -command => \&item1);
$menu->add('command', -label => 'Two', -command => \&item2);

# Set up binding so that, when the right mouse button (3)
# is clicked on the main window ($mw), &showmenu() is
# called and is given the x and y coordinates of the click.
$mw->bind('<3>', [\&showmenu, Ev('x'), Ev('y')]);

# Start the program, with the main window in the front.
$mw->focus();
MainLoop;

# Called when right mouse button is clicked on the main window.
sub showmenu {
  my ($self, $x, $y) = @_;
  $menu->post($x, $y);  # Show the popup menu
}

# Called when menu items are selected.
sub item1 { print "Item 1!\n" }
sub item2 { print "Item 2!\n" }
