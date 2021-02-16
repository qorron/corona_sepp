#!/usr/bin/perl
use strict;
use warnings;
use 5.020;
use Data::Dumper;

use DBIx::Simple;
use Date::Parse;
use POSIX qw(strftime);
use File::Slurper qw(write_text);
use File::Touch;

my $tmp_marker = '/tmp/impfst_done_for_today';
my $file = '/var/www/impfst.at/index.html';

# Connecting to a MySQL database
my $db = DBIx::Simple->connect(
	'DBI:Pg:database=corona;host=127.0.0.1',    # DBI source specification
	$ENV{CORONA_DB_USER},                       # Username and password
	$ENV{CORONA_DB_PASS},
	{ RaiseError => 1 }                         # Additional options
);
my @fresh_data = $db->select( 'impfst_28d_done', ['teilgeimpfte_est_date', 'teilgeimpfte_est_days', 'bevoelkerung', 'teilgeimpfte', 'teilgeimpfte_diff'], { BundeslandID => 10 } )->hashes;
if (@fresh_data) {
	exit if -e $tmp_marker;
	my $time = str2time( $fresh_data[0]->{teilgeimpfte_est_date} );

	#say strftime('%d.%m.%Y', localtime($time));
	my $done_date = strftime( '%d.%m.%Y',       localtime($time) );
	my $now_date  = strftime( '%d.%m.%Y %H:%M', localtime() );
	my $d = {
		inh       => $fresh_data[0]->{bevoelkerung},
		vax       => $fresh_data[0]->{teilgeimpfte},
		vul       => $fresh_data[0]->{bevoelkerung} - $fresh_data[0]->{teilgeimpfte},
		vax_28 => $fresh_data[0]->{teilgeimpfte} - $fresh_data[0]->{teilgeimpfte_diff},
		vax_diff  => $fresh_data[0]->{teilgeimpfte_diff},
		vax_per_d => $fresh_data[0]->{teilgeimpfte_diff} / 28,
		days      => $fresh_data[0]->{teilgeimpfte_est_days},
	};
	my $html      = <<XXX;
<html>
<head>
</head>
<body>
Based upon the data available from <a href="https://orf.at/">orf.at</a> all Austrians will recieve their first SARS Cov2 jab by this date:<br>
<h1>$done_date</h1>
This was calculated using a linear extrapolation of the vaccination progress over the last 28 days.<br>
Last updated: $now_date (once a day unless something goes wrong)
This site is not affiliated with anyone and was only created to take my mind off the fact that a 'wird scho nix sein' person I recently met was tested positive the very next day.
Source/Contact/etc.: <a href="https://github.com/qorron/corona_sepp">github</a><br>
Update: just got tested negative on day 3 after the incident. so: yay!<br>
Update2: second test, 5 days after the incident still negative.<br>
<br>Oh, and see what may happen if you <a href="http://impfst.net">impfst.net</a>.<br><br>
<b>Disclaimer:</b> 
It has been brought to my attention that things are not as abundantly clear as I thought they where by 
describing a minimal set of details and leave figuring out the rest to the reader.
So, here's the fine print: 
An extrapolation is a guess of the future based upon the past that will obviously fail if the future behaves differently than the past (which it most likely will do in this case).
You want to do the numbers game? Please be my guest. 
According to the data, Austria has $d->{inh} inhabitants.
$d->{vax} got their first jab. 
That leaves $d->{vul} still vulnerable. 
28 days ago $d->{vax_28} had their first shot. 
Thats $d->{vax_diff} in 28 days or $d->{vax_per_d} per day.
Dividing $d->{vul} by $d->{vax_per_d} leaves us with approximately $d->{days} days.
Addding this to the date today yields the date above.
</body>
</html>
XXX
	write_text( $file, $html );
	touch($tmp_marker);
}
else {
	unlink $tmp_marker if -e $tmp_marker;
	#warn "update failed!";
}


