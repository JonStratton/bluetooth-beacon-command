#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Std;

# Defaults
my $CONFIG = '/etc/bluetooth-beacon-command.conf';
my @BEACONS = (''); # "Device XX:..:ZZ Blah Blah" from bluetoothctl devices
my @SEECOMMANDS = ();
my @NOTSEECOMMANDS = ();
my $SLEEP = 5;
my $GONE_DELAY = 60;
my $VERBOSE = 1;

# -c for custom config
my %opts = ();
getopt('c', \%opts);
$CONFIG = $opts{'c'} if exists($opts{'c'});
my %config = ();
%config = &readConfig($CONFIG) if (-e $CONFIG);
@BEACONS = split(/\s*,\s*/, $config{'BEACONS'}) if exists($config{'BEACONS'});
@SEECOMMANDS = split(/\s*;\s*/, $config{'SEECOMMANDS'}) if exists($config{'SEECOMMANDS'});
@NOTSEECOMMANDS = split(/\s*;\s*/, $config{'NOTSEECOMMANDS'}) if exists($config{'NOTSEECOMMANDS'});
$SLEEP = $config{'SLEEP'} if exists($config{'SLEEP'});
$GONE_DELAY = $config{'GONE_DELAY'} if exists($config{'GONE_DELAY'});
$VERBOSE = ($config{'VERBOSE'}) if exists($config{'VERBOSE'});

&main();
exit(0);

sub main() {
my $last_seen;
system('bluetoothctl scan on > /dev/null &');
while(1) {
   sleep $SLEEP;
   if (open(my $btIn_h, '-|', 'bluetoothctl devices')) {
      my @matchingBeacons = ();
      while(my $btLine = <$btIn_h>) {
         chomp($btLine);
         push(@matchingBeacons, grep { /^\Q$btLine\E$/ } @BEACONS);
      }

      my @execCommands = ();
      # New Beacon
      if (@matchingBeacons && !$last_seen) {
         printf("%s|New Beacon|%s\n", getTime(), join(', ', @matchingBeacons)) if ($VERBOSE);
         push(@execCommands, @SEECOMMANDS);
      }

      # Save the time for the timeout
      $last_seen = time() if (@matchingBeacons);

      # Timeout of old beacons
      if (!@matchingBeacons && $last_seen && (time() - $last_seen) >= $GONE_DELAY) {
	 undef($last_seen);
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
}

# Misc
sub getTime() {
   my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
   return(sprintf("%04d%02d%02d %02d%02d%02d", ($year+1900), ($mon+1), $mday, $hour, $min, $sec));
}

sub readConfig() {
my ($configFile) = @_;
my %config = ();
if (open(my $config_h, '<', $configFile)) {
   while (my $configLine = <$config_h>) {
      chomp($configLine);
      my ($item, $value) = split(/\s*=\s*/, $configLine);
      $config{$item} = $value;
   }
   close($config_h);
}
return(%config);
}
