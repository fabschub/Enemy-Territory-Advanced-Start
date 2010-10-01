#!/usr/bin/perl -w

use FindBin;
use lib "$FindBin::RealBin/../lib";
use strict;
use warnings;
use File::Basename;
# needs libconfig-tiny-perl
use Config::Tiny;
# needs libcurses-ui-perl
use Curses::UI;
$Curses::UI::debug = 0;

# Create a config
my $Config = Config::Tiny->new();
my $etas_conf = "$ENV{'HOME'}/.config/etas.conf";
if ( !-e $etas_conf ) {
  $Config->{_}->{etworkdir} = '/usr/local/games/enemy-territory';
  $Config->{options}->{newx} = '0';
  $Config->{options}->{mumble} = '0';
  $Config->write( "$etas_conf" );
}


$Config = Config::Tiny->read( "$etas_conf" );
# Reading properties
my $etworkdir = $Config->{_}->{etworkdir};
my $newx = $Config->{options}->{newx};
my $mumble = $Config->{options}->{mumble};

my $overlay = '';
my $xinit = '';
my $display = '';
my $name = 'ETplayer';

my $etwolfdir = "$ENV{'HOME'}/.etwolf";
my $keysdir = "$etwolfdir/etmain/etkeys";


# create a list of all *.etkey files in the current directory
opendir(DIR, $keysdir);
my @etkeys = sort(grep(/\.etkey$/,readdir(DIR)));
closedir(DIR);

my $currentkey = basename(readlink("$etwolfdir/etmain/etkey"));
my( $currentkeyindex )= grep { $etkeys[$_] eq $currentkey } 0..$#etkeys;

my $opt_values = ['newx', 'overlay'];


my $cui = new Curses::UI(
  -color_support => 1,
  -clear_on_exit => 1);

my $win1 = $cui->add(
  'win1', 'Window',
  -border => 1,
  -y      => 1,
  -bfg    => 'red');


$win1->add("d1", "TextEntry", 
  -border    => 0,
  -fg        => "green",
  -x         => 2 ,
  -y         => 1 ,
  -width     => 5,
  -text      => "Name",
  -focusable => 0,
  -readonly  => 1,
);


my $name_input = $win1->add(
  "name_input", "TextEntry", 
  -border => 1,
  -bfg    => "blue",
  -x      => 10 ,
  -width  => 22,
  -text   => "$name"
);


my $random_but = $win1->add("random_but", "Buttonbox" ,
  -buttons => [ { -label => "< Random >", -onpress => \&rname } ] ,
  -border  => 0,
  -y => 1,
  -x => 40
);


my $etkey_lbox = $win1->add(
  'etkey_lbox', 'Listbox',
  -title      => 'Choose Etkey:',
  -radio      => '1',
  -border     => 1,
  -bfg        => 'green',
  -wraparound => 1,
  -vscrollbar => 1,
  -x          => 10,
  -y          => 3,
  -width      => 40,
  -height     => 12,
  -values     => [@etkeys],
  -selected   => $currentkeyindex,
);


my $options_lbox = $win1->add(
  'options_lbox', 'Listbox',
  -title      => 'Options',
  -multi      => 1,
  -border     => 1,
  -bfg        => 'green',
  -wraparound => 1,
  -vscrollbar => 1,
  -y          => 16,
  -x          => 10,
  -width      => 26,
  -height     => 6,
  -values     => ['newx', 'mumble'],
  -labels     => {newx => 'own xserver', mumble => 'mumble-overlay'},
  -selected   => {0=>$newx, 1=>$mumble},
);

my $but1 = $win1->add("addbutton", "Buttonbox" ,
  -buttons => [ { -label => "< Start ET >", -onpress => \&start } ] ,
  -border  => 0,
  -y       => 18,
  -x       => 40
);


sub exit_dialog() {
  my $return = $cui->dialog(
    -message   => "Do you really want to quit?",
    -title     => "Are you sure???",
    -buttons   => ['yes', 'no'],
  );

  exit(0) if $return;
}


sub rname {
# just use random-hostname from GRML distribution at the moment
  $name_input->text(`random-hostname`);
}


sub start {
  my $name=$name_input->get();
  my $etkey_selected=$etkey_lbox->get();
  if ($etkey_selected ne $currentkey) {
    unlink ("$etwolfdir/etmain/etkey");
    symlink ("$keysdir/$etkey_selected","$etwolfdir/etmain/etkey");
  };

  # Get status of options
  my (@optstat) = $options_lbox->get;
  # Set options to 0 (disabled)
  $Config->{options}->{newx} = '0';
  $Config->{options}->{mumble} = '0';
  # If options are checked, set them to 1 (enabled)
  foreach (@optstat) {
    $Config->{options}->{$_} = '1';
  }
  # Write config file
  $Config->write( "$etas_conf" ); 

  my $xstat = grep { $optstat[$_] eq 'newx' } 0..$#optstat;
  if (defined $xstat && $xstat == 1) {
    $xinit = "xinit";
    $display = "-- :1";
  }

  my $mstat = grep { $optstat[$_] eq 'mumble' } 0..$#optstat;
  if (defined $mstat && $mstat == 1) {
    $overlay = "mumble-overlay";
  }

  # Start Enemy Territory
  exec ("$xinit " .  "$overlay " . "$etworkdir\/et" . " @ARGV " . "+name '$name'" . " $display");

  exit(0);
}

$cui->set_binding( sub {exit_dialog;}, "\cQ");
$cui->mainloop;

