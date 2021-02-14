#!/usr/bin/perl
use strict;
use warnings;
use 5.020;
use Data::Dumper;

my $days = $ARGV[0];

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
Gruppe_24_M_1
Gruppe_24_W_1
Gruppe_24_D_1
Gruppe_25_34_M_1
Gruppe_25_34_W_1
Gruppe_25_34_D_1
Gruppe_35_44_M_1
Gruppe_35_44_W_1
Gruppe_35_44_D_1
Gruppe_45_54_M_1
Gruppe_45_54_W_1
Gruppe_45_54_D_1
Gruppe_55_64_M_1
Gruppe_55_64_W_1
Gruppe_55_64_D_1
Gruppe_65_74_M_1
Gruppe_65_74_W_1
Gruppe_65_74_D_1
Gruppe_75_84_M_1
Gruppe_75_84_W_1
Gruppe_75_84_D_1
Gruppe__84_M_1
Gruppe__84_W_1
Gruppe__84_D_1
Gruppe_24_M_2
Gruppe_24_W_2
Gruppe_24_D_2
Gruppe_25_34_M_2
Gruppe_25_34_W_2
Gruppe_25_34_D_2
Gruppe_35_44_M_2
Gruppe_35_44_W_2
Gruppe_35_44_D_2
Gruppe_45_54_M_2
Gruppe_45_54_W_2
Gruppe_45_54_D_2
Gruppe_55_64_M_2
Gruppe_55_64_W_2
Gruppe_55_64_D_2
Gruppe_65_74_M_2
Gruppe_65_74_W_2
Gruppe_65_74_D_2
Gruppe_75_84_M_2
Gruppe_75_84_W_2
Gruppe_75_84_D_2
Gruppe__84_M_2
Gruppe__84_W_2
Gruppe__84_D_2
EingetrageneImpfungenBioNTechPfizer_1
EingetrageneImpfungenModerna_1
EingetrageneImpfungenAstraZeneca_1
EingetrageneImpfungenBioNTechPfizer_2
EingetrageneImpfungenModerna_2
EingetrageneImpfungenAstraZeneca_2
);


say "create or replace view impfst_${days}d_diff as select";
my @fields = ();
for (@abs) {
	push @fields,"\timpfst_now.$_";
}
for (@diff) {
	push @fields,"\timpfst_now.$_";
	my $name = $_;
	$name .= '_diff';
	push @fields,"\t(impfst_now.$_ - impfst_${days}_days_ago.$_) as $name";
}
say join ",\n", @fields;
say "from impfst_now join impfst_${days}_days_ago using ( BundeslandID);";


