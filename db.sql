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

create or replace view district_date as 
	select *, date_trunc('day', timestamp) as date 
		from districts ;
create or replace view district_max as 
	select max(anzahl) as anzahl, max(anzahl_inzidenz) as anzahl_inzidenz, bezirk, gkz, date 
		from district_date 
		group by bezirk, gkz, date;
create or replace view district_diff as 
	select a.anzahl - b.anzahl as anzahl_diff, a.anzahl_inzidenz - b.anzahl_inzidenz as anzahl_inzidenz_diff,  a.date, a.bezirk, a.gkz 
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
create or replace view district_diff_14 as
	select bezirk, gkz, sum(anzahl_diff) as anzahl_diff, sum (anzahl_inzidenz_diff) as anzahl_inzidenz_diff 
		from district_diff 
		where age(date) <= '14 days' 
		group by bezirk, gkz;


grant INSERT ON districts TO corona_editor_role;
grant SELECT ON districts TO corona_editor_role; 
grant SELECT ON districts TO corona_viewer_role;
grant SELECT ON district_date TO corona_viewer_role;
grant SELECT ON district_diff TO corona_viewer_role;
grant SELECT ON district_diff_1 TO corona_viewer_role;
grant SELECT ON district_diff_14 TO corona_viewer_role;
grant SELECT ON district_diff_5 TO corona_viewer_role;
grant SELECT ON district_max TO corona_viewer_role;

