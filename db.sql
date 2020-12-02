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








