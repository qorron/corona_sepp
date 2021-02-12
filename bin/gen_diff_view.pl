#!/usr/bin/perl
use strict;
use warnings;
use 5.020;
use Data::Dumper;


my @abs =
qw(
BundeslandID
Name
);

my @diff = 
qw(
Datum
Bevölkerung
EingetrageneImpfungen
EingetrageneImpfungenPro100
Teilgeimpfte
TeilgeimpftePro100
Vollimmunisierte
VollimmunisiertePro100
"Gruppe<24_M_1"
"Gruppe<24_W_1"
"Gruppe<24_D_1"
"Gruppe_25-34_M_1"
"Gruppe_25-34_W_1"
"Gruppe_25-34_D_1"
"Gruppe_35-44_M_1"
"Gruppe_35-44_W_1"
"Gruppe_35-44_D_1"
"Gruppe_45-54_M_1"
"Gruppe_45-54_W_1"
"Gruppe_45-54_D_1"
"Gruppe_55-64_M_1"
"Gruppe_55-64_W_1"
"Gruppe_55-64_D_1"
"Gruppe_65-74_M_1"
"Gruppe_65-74_W_1"
"Gruppe_65-74_D_1"
"Gruppe_75-84_M_1"
"Gruppe_75-84_W_1"
"Gruppe_75-84_D_1"
"Gruppe_>84_M_1"
"Gruppe_>84_W_1"
"Gruppe_>84_D_1"
"Gruppe<24_M_2"
"Gruppe<24_W_2"
"Gruppe<24_D_2"
"Gruppe_25-34_M_2"
"Gruppe_25-34_W_2"
"Gruppe_25-34_D_2"
"Gruppe_35-44_M_2"
"Gruppe_35-44_W_2"
"Gruppe_35-44_D_2"
"Gruppe_45-54_M_2"
"Gruppe_45-54_W_2"
"Gruppe_45-54_D_2"
"Gruppe_55-64_M_2"
"Gruppe_55-64_W_2"
"Gruppe_55-64_D_2"
"Gruppe_65-74_M_2"
"Gruppe_65-74_W_2"
"Gruppe_65-74_D_2"
"Gruppe_75-84_M_2"
"Gruppe_75-84_W_2"
"Gruppe_75-84_D_2"
"Gruppe_>84_M_2"
"Gruppe_>84_W_2"
"Gruppe_>84_D_2"
EingetrageneImpfungenBioNTechPfizer_1
EingetrageneImpfungenModerna_1
EingetrageneImpfungenAstraZeneca_1
EingetrageneImpfungenBioNTechPfizer_2
EingetrageneImpfungenModerna_2
EingetrageneImpfungenAstraZeneca_2
);


say "create or replace view impfst_28d_diff as select";
my @fields = ();
for (@abs) {
	push @fields,"\timpfst_now.$_";
}
for (@diff) {
	push @fields,"\timpfst_now.$_";
	my $name = $_;
	if ($name =~ /^"(.+)"$/) {
		$name = qq'"$1_diff"';
	} else {
		$name .= '_diff';
	}
	push @fields,"\t(impfst_now.$_ - impfst_28_days_ago.$_) as $name";
}
say join ",\n", @fields;
say "from impfst_now join impfst_28_days_ago using ( BundeslandID);";


