#!/usr/bin/env perl

use strict;
use warnings;

my @BEACONS = (''); # "Device XX:..:ZZ Blah Blah" from bluetoothctl devices
my @SEECOMMANDS = ();
my @NOTSEECOMMANDS = ();
my $SLEEP = 5;
my $GONE_DELAY = 60;
my $VERBOSE = 1;

my $LAST_SEEN;

sub getTime() {
   my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
   return(sprintf("%04d%02d%02d %02d%02d%02d", ($year+1900), ($mon+1), $mday, $hour, $min, $sec));
}

system('bluetoothctl scan on > /dev/null &');
while(1) {
   sleep $SLEEP;
   if (open(my $btIn_h, '-|', 'bluetoothctl devices')) {
      my @matchingBeacons = ();
      while(my $btLine = <$btIn_h>) {
         chomp($btLine);
         push(@matchingBeacons, grep { /^$btLine$/ } @BEACONS);
      }

      my @execCommands = ();
      # New Beacon
      if (@matchingBeacons && !$LAST_SEEN) {
         printf("%s|New Beacon|%s\n", getTime(), join(', ', @matchingBeacons)) if ($VERBOSE);
         push(@execCommands, @SEECOMMANDS);
      }

      # Save the time for the timeout
      $LAST_SEEN = time() if (@matchingBeacons);

      # Timeout of old beacons
      if (!@matchingBeacons && $LAST_SEEN && (time() - $LAST_SEEN) >= $GONE_DELAY) {
	 undef($LAST_SEEN);
         printf("%s|Beacon Gone\n", getTime()) if ($VERBOSE);
         push(@execCommands, @NOTSEECOMMANDS);
      }

      # Execute command
      foreach my $command (@execCommands) {
         printf("%s|Executing|%s\n", getTime(), $command) if ($VERBOSE);
         system($command);
      }

      close($btIn_h);
   }
}
