drop table districts;
create table districts (
	bezirk text not null,
	anzahl integer not null,
	anzahl_inzidenz float not null,
	gkz integer not null,
	timestamp timestamp not null,
	etag text, 
	unique(gkz, timestamp)
);

anzahl_inzidenz = x/100k
anzahl = x

x/(x/100k) = x* 100k/x = 100k



create or replace view districts_inh as 
	select *, round(anzahl/anzahl_inzidenz*100000) as inhabitants
		from districts where anzahl_inzidenz > 0;
create or replace view district_date as 
	select *, date_trunc('day', timestamp) as date 
		from districts_inh ;
create or replace view district_max as 
	select max(anzahl) as anzahl, max(anzahl_inzidenz) as anzahl_inzidenz, max(inhabitants) as inhabitants, bezirk, gkz, date 
		from district_date 
		group by bezirk, gkz, date;
create or replace view district_diff as 
	select a.anzahl - b.anzahl as anzahl_diff, a.anzahl_inzidenz - b.anzahl_inzidenz as anzahl_inzidenz_diff, a.inhabitants, a.date, a.bezirk, a.gkz 
		from district_max as a, district_max as b 
		where a.date = b.date + interval '1 day' and a.gkz = b.gkz;

create or replace view district_diff_1 as
	select bezirk, gkz, sum(anzahl_diff) as anzahl_diff, sum (anzahl_inzidenz_diff) as anzahl_inzidenz_diff 
		from district_diff 
		where age(date) <= '1 days' 
		group by bezirk, gkz;
create or replace view district_diff_5 as
	select bezirk, gkz, sum(anzahl_diff) as anzahl_diff, sum (anzahl_inzidenz_diff) as anzahl_inzidenz_diff 
		from district_diff 
		where age(date) <= '5 days' 
		group by bezirk, gkz;
create or replace view district_diff_7 as
	select bezirk, gkz, sum(anzahl_diff) as anzahl_diff, sum (anzahl_inzidenz_diff) as anzahl_inzidenz_diff 
		from district_diff 
		where age(date) <= '7 days' 
		group by bezirk, gkz;
create or replace view district_diff_14 as
	select bezirk, gkz, sum(anzahl_diff) as anzahl_diff, sum (anzahl_inzidenz_diff) as anzahl_inzidenz_diff 
		from district_diff 
		where age(date) <= '14 days' 
		group by bezirk, gkz;

create or replace view district_7d_incidence as
	select a.bezirk as bezirk, a.gkz as gkz, max(a.inhabitants) as inhabitants, sum(a.anzahl_diff) as anzahl_diff, sum(a.anzahl_inzidenz_diff) as seven_day_inzidenz, b.date as date
        from district_diff as a, district_max as b
        where age(b.date, a.date) <= '7 days' and age(b.date, a.date) > '0 days' and a.gkz = b.gkz
        group by a.bezirk, a.gkz, b.date;

grant INSERT ON districts TO corona_editor_role;
grant SELECT ON districts TO corona_editor_role; 
grant SELECT ON districts TO corona_viewer_role;
grant SELECT ON district_date TO corona_viewer_role;
grant SELECT ON district_diff TO corona_viewer_role;
grant SELECT ON district_diff_1 TO corona_viewer_role;
grant SELECT ON district_diff_14 TO corona_viewer_role;
grant SELECT ON district_diff_5 TO corona_viewer_role;
grant SELECT ON district_max TO corona_viewer_role;


drop table impfst cascade;
create table impfst (
	Datum timestamp with time zone not null,
	BundeslandID integer not null,
	Bevölkerung integer,
	Name text,
	EingetrageneImpfungen integer,
	EingetrageneImpfungenPro100 float,
	Teilgeimpfte integer,
	TeilgeimpftePro100 float,
	Vollimmunisierte integer,
	VollimmunisiertePro100 float,
	Gruppe_24_M_1 integer,
	Gruppe_24_W_1 integer,
	Gruppe_24_D_1 integer,
	Gruppe_25_34_M_1 integer,
	Gruppe_25_34_W_1 integer,
	Gruppe_25_34_D_1 integer,
	Gruppe_35_44_M_1 integer,
	Gruppe_35_44_W_1 integer,
	Gruppe_35_44_D_1 integer,
	Gruppe_45_54_M_1 integer,
	Gruppe_45_54_W_1 integer,
	Gruppe_45_54_D_1 integer,
	Gruppe_55_64_M_1 integer,
	Gruppe_55_64_W_1 integer,
	Gruppe_55_64_D_1 integer,
	Gruppe_65_74_M_1 integer,
	Gruppe_65_74_W_1 integer,
	Gruppe_65_74_D_1 integer,
	Gruppe_75_84_M_1 integer,
	Gruppe_75_84_W_1 integer,
	Gruppe_75_84_D_1 integer,
	Gruppe__84_M_1 integer,
	Gruppe__84_W_1 integer,
	Gruppe__84_D_1 integer,
	Gruppe_24_M_2 integer,
	Gruppe_24_W_2 integer,
	Gruppe_24_D_2 integer,
	Gruppe_25_34_M_2 integer,
	Gruppe_25_34_W_2 integer,
	Gruppe_25_34_D_2 integer,
	Gruppe_35_44_M_2 integer,
	Gruppe_35_44_W_2 integer,
	Gruppe_35_44_D_2 integer,
	Gruppe_45_54_M_2 integer,
	Gruppe_45_54_W_2 integer,
	Gruppe_45_54_D_2 integer,
	Gruppe_55_64_M_2 integer,
	Gruppe_55_64_W_2 integer,
	Gruppe_55_64_D_2 integer,
	Gruppe_65_74_M_2 integer,
	Gruppe_65_74_W_2 integer,
	Gruppe_65_74_D_2 integer,
	Gruppe_75_84_M_2 integer,
	Gruppe_75_84_W_2 integer,
	Gruppe_75_84_D_2 integer,
	Gruppe__84_M_2 integer,
	Gruppe__84_W_2 integer,
	Gruppe__84_D_2 integer,
	EingetrageneImpfungenBioNTechPfizer_1 integer,
	EingetrageneImpfungenModerna_1 integer,
	EingetrageneImpfungenAstraZeneca_1 integer,
	EingetrageneImpfungenBioNTechPfizer_2 integer,
	EingetrageneImpfungenModerna_2 integer,
	EingetrageneImpfungenAstraZeneca_2 integer,
	unique (Datum, BundeslandID)
);

create or replace view impfst_7_days_ago as
    select * from impfst where age(date_trunc('day', Datum)) = '8 days' ;

create or replace view impfst_28_days_ago as
    select * from impfst where age(date_trunc('day', Datum)) = '29 days' ;

create or replace view impfst_now as
    select * from impfst where age(date_trunc('day', Datum)) = '1 day' ;

create or replace view impfst_7d_est as
	select * , 
		(Bevölkerung - EingetrageneImpfungen) * 7 / EingetrageneImpfungen_diff as EingetrageneImpfungen_est_days,
		(100 - EingetrageneImpfungenPro100) * 7 / EingetrageneImpfungenPro100_diff as EingetrageneImpfungenPro100_est_days,
		(Bevölkerung - Teilgeimpfte) * 7 / Teilgeimpfte_diff as Teilgeimpfte_est_days,
		(100 - TeilgeimpftePro100) * 7 / TeilgeimpftePro100_diff as TeilgeimpftePro100_est_days,
		(Bevölkerung - Vollimmunisierte) * 7 / Vollimmunisierte_diff as Vollimmunisierte_est_days,
		(100 - VollimmunisiertePro100) * 7 / VollimmunisiertePro100_diff as VollimmunisiertePro100_est_days
 from impfst_7d_diff;

create or replace view impfst_7d_done as
	select *,
		now() + '1 day'::interval * EingetrageneImpfungen_est_days as EingetrageneImpfungen_est_date,
		now() + '1 day'::interval * EingetrageneImpfungenPro100_est_days as EingetrageneImpfungenPro100_est_date,
		now() + '1 day'::interval * Teilgeimpfte_est_days as Teilgeimpfte_est_date,
		now() + '1 day'::interval * TeilgeimpftePro100_est_days as TeilgeimpftePro100_est_date,
		now() + '1 day'::interval * Vollimmunisierte_est_days as Vollimmunisierte_est_date,
		now() + '1 day'::interval * VollimmunisiertePro100_est_days as VollimmunisiertePro100_est_date
from impfst_7d_est;

create or replace view impfst_28d_est as
	select * , 
		(Bevölkerung - EingetrageneImpfungen) * 28 / EingetrageneImpfungen_diff as EingetrageneImpfungen_est_days,
		(100 - EingetrageneImpfungenPro100) * 28 / EingetrageneImpfungenPro100_diff as EingetrageneImpfungenPro100_est_days,
		(Bevölkerung - Teilgeimpfte) * 28 / Teilgeimpfte_diff as Teilgeimpfte_est_days,
		(100 - TeilgeimpftePro100) * 28 / TeilgeimpftePro100_diff as TeilgeimpftePro100_est_days,
		(Bevölkerung - Vollimmunisierte) * 28 / Vollimmunisierte_diff as Vollimmunisierte_est_days,
		(100 - VollimmunisiertePro100) * 28 / VollimmunisiertePro100_diff as VollimmunisiertePro100_est_days
 from impfst_28d_diff;

create or replace view impfst_28d_done as
	select *,
		now() + '1 day'::interval * EingetrageneImpfungen_est_days as EingetrageneImpfungen_est_date,
		now() + '1 day'::interval * EingetrageneImpfungenPro100_est_days as EingetrageneImpfungenPro100_est_date,
		now() + '1 day'::interval * Teilgeimpfte_est_days as Teilgeimpfte_est_date,
		now() + '1 day'::interval * TeilgeimpftePro100_est_days as TeilgeimpftePro100_est_date,
		now() + '1 day'::interval * Vollimmunisierte_est_days as Vollimmunisierte_est_date,
		now() + '1 day'::interval * VollimmunisiertePro100_est_days as VollimmunisiertePro100_est_date
from impfst_28d_est;

