# bluetooth-beacon-command
This is a simple script that will either run a command when it sees a particular Bluetooth device, or run a command when a known Bluetooth device is no longer visible. As you can tell by the example config file, I use this script to turn on a security camera when I leave.

As these signals can be flakey, the config has an option “GONE_DELAY” with is the number of seconds a device isnt seen for before its actually considered gone. 

	$ perl bluetooth-beacon-command.pl -c ./bluetooth-beacon-command-jon.conf
	20230819 201429|New Beacon|Device 99:99:99:99:99:99 REDACTED
	20230819 201429|Executing|kill `pidof motion` >/dev/null 2>&1
	20230819 201557|Beacon Gone
	20230819 201557|Executing|motion -c ~/motion/motion.conf >/dev/null 2>&1 &
	20230819 201622|New Beacon|Device 99:99:99:99:99:99 REDACTED
	20230819 201622|Executing|kill `pidof motion` >/dev/null 2>&1
