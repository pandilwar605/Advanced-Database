CREATE DATABASE sp;
--Connecting database 
\c sp; 


create table sailor(
sid int primary key, 
sname varchar(255), 
rating int
);

\qecho 'Populating Tables'
INSERT INTO sailor VALUES(22,   'Dustin',       7),(29,   'Brutus',       1),(31,   'Lubber',       8),(32,   'Andy',         8),
(58,   'Rusty',        10),(64,   'Horatio',      7),(71,   'Zorba',        10),(75,   'David',        8),(74,   'Horatio',      9),
(85,   'Art',          3),(95,   'Bob',          3);


create table boat(
bid int primary key, 
bname varchar(255), 
color varchar(255)
);

\qecho 'Populating Tables'
INSERT INTO boat VALUES(101,	'Interlake',	'blue'),(102,	'Sunset',	'red'),(103,	'Clipper',	'green'),
(104,	'Marine',	'red'),(105,    'Indianapolis',     'blue');

create table reserves(
sid int references sailor(sid), 
bid int references boat(bid), 
day varchar(255)
);

--Populating Tables
INSERT INTO reserves VALUES(22,	101,	'Monday'),(22,	102,	'Tuesday'),(22,	103,	'Wednesday'),(22,	105,	'Wednesday'),
(31,	102,	'Thursday'),(31,	103,	'Friday'),(31, 104,	'Saturday'),(64,	101,	'Sunday'),(64,	102,	'Monday'),
(74,	102,	'Saturday');

\qecho 'Question 1.1'

\qecho 'Sailor'
select * from sailor;

\qecho 'Boat'
select * from boat;

\qecho 'Reserves'
select * from reserves;

--1)
\qecho 'Question 1.2'

\qecho ''
\qecho 'a)'
\qecho ''
insert into sailor values (null,'sanket',5);
\qecho 'Im inserting null values, but sid is primary key hence it will not allow it null value in column sid violates not-null constraint'

--2)
\qecho ''
\qecho 'b)'
\qecho ''
insert into sailor (sname,rating) values ('sanket',5);
\qecho 'will not allow since sid is primary key and we need to provide some value'
alter table reserves drop constraint reserves_sid_fkey;
alter table sailor drop constraint sailor_pkey;
alter table sailor alter column sid drop not null;
insert into sailor (sname,rating) values ('sanket',5);
\qecho 'this is allowed since we dont have primary key constraint and default null value is added for sid'

--3)
\qecho ''
\qecho 'c)'
\qecho ''
drop table sailor;
create table sailor(sid int primary key, sname varchar(255), rating int);
INSERT INTO sailor VALUES(22,   'Dustin',       7);
INSERT INTO sailor VALUES(29,   'Brutus',       1);
INSERT INTO sailor VALUES(31,   'Lubber',       8);
INSERT INTO sailor VALUES(32,   'Andy',         8);
INSERT INTO sailor VALUES(58,   'Rusty',        10);
INSERT INTO sailor VALUES(64,   'Horatio',      7);
INSERT INTO sailor VALUES(71,   'Zorba',        10);
INSERT INTO sailor VALUES(75,   'David',        8);
INSERT INTO sailor VALUES(74,   'Horatio',      9);
INSERT INTO sailor VALUES(85,   'Art',          3);
INSERT INTO sailor VALUES(95,   'Bob',          3);

INSERT INTO sailor VALUES(22,   'Sanket',     	5);
\qecho 'ERROR: duplicate key value violates unique constraint "sailor_pkey" Detail: Key (sid)=(22) already exists.'
alter table sailor drop constraint sailor_pkey;
INSERT INTO sailor VALUES(22,   'Sanket',     	5);
\qecho 'This will work since we dont have primary key contraint, primary key does not allow duplicates'

--4)
\qecho ''
\qecho 'd)'
\qecho ''
delete from sailor where sname='Sanket';
alter table sailor add constraint sailor_pkey primary key (sid);
alter table reserves add constraint reserves_sid_fkey FOREIGN KEY (sid) references sailor(sid);
delete from sailor where sid=22;
\qecho '22 is a sid which is referred in reserves table hence we can not directly delete this id ' 


--5)
\qecho ''
\qecho 'e)'
\qecho ''

insert into reserves values(1,101,'Monday');
\qecho 'Since sid 1 is not available in sailor table, we can not insert it because of foreign key violation '


--6)
\qecho ''
\qecho 'f)'
\qecho ''

delete from sailor where sid=22;

\qecho 'To achieve this, we need to use cascade delete constraint'

alter table reserves drop constraint reserves_sid_fkey;
alter table reserves drop constraint reserves_bid_fkey;
alter table reserves add constraint reserves_sid_fkey foreign key (sid) references sailor(sid) on delete cascade;
alter table reserves add constraint reserves_bid_fkey foreign key (bid) references boat(bid) on delete cascade;

delete from sailor where sid=22;
\qecho 'This will work and it will delete all the entries from reserves table which belong to sid 22 because we have on cascade delete constraint'
\qecho ''
\qecho 'Problem Set 2'
drop table reserves;
drop table sailor;
drop table boat;

create table sailor(
sid int primary key, 
sname varchar(255), 
rating int
);

--Populating Tables
INSERT INTO sailor VALUES(22,   'Dustin',       7),(29,   'Brutus',       1),(31,   'Lubber',       8),(32,   'Andy',         8),
(58,   'Rusty',        10),(64,   'Horatio',      7),(71,   'Zorba',        10),(75,   'David',        8),(74,   'Horatio',      9),
(85,   'Art',          3),(95,   'Bob',          3);


create table boat(
bid int primary key, 
bname varchar(255), 
color varchar(255)
);

--Populating Tables
INSERT INTO boat VALUES(101,	'Interlake',	'blue'),(102,	'Sunset',	'red'),(103,	'Clipper',	'green'),
(104,	'Marine',	'red'),(105,    'Indianapolis',     'blue');

create table reserves(
sid int references sailor(sid), 
bid int references boat(bid), 
day varchar(255)
);

--Populating Tables
INSERT INTO reserves VALUES(22,	101,	'Monday'),(22,	102,	'Tuesday'),(22,	103,	'Wednesday'),(22,	105,	'Wednesday'),
(31,	102,	'Thursday'),(31,	103,	'Friday'),(31, 104,	'Saturday'),(64,	101,	'Sunday'),(64,	102,	'Monday'),
(74,	102,	'Saturday');


--1)
\qecho ''
\qecho 'Question 2.1'
select s.sid,s.rating from sailor s; 
--2)
\qecho 'Question 2.2'
select s.sid, s.sname, s.rating from sailor s where s.rating in (2,3,4,5,6,7,11);

--3)
\qecho 'Question 2.3'
select b.bid,b.bname,b.color from boat b, sailor s, reserves r 
where b.bid=r.bid and r.sid=s.sid and s.rating >7 and b.color!='red';

--4)
\qecho 'Question 2.4'
select b.bid,b.bname from boat b, reserves r 
where b.bid=r.bid and r.day in('Saturday','Sunday')
except 
select b.bid,b.bname from boat b, reserves r 
where b.bid=r.bid and r.day in('Tuesday');

--5)
--select distinct(s.sid) from sailor s, boat b,reserves r where s.sid=r.sid and b.bid = r.bid and b.color='red'
--and s.sid in(select s.sid from sailor s, boat b,reserves r where s.sid=r.sid and b.bid = r.bid and b.color='green')

\qecho 'Question 2.5'
select s.sid from sailor s, boat b,reserves r where s.sid=r.sid and b.bid = r.bid and b.color='red'
intersect
select s.sid from sailor s, boat b,reserves r where s.sid=r.sid and b.bid = r.bid and b.color='green';

--6)
\qecho 'Question 2.6'
select s.sid,s.sname from sailor s 
where s.sid in ( select r1.sid from reserves r1, reserves r2 where r1.sid=r2.sid and r1.bid !=r2.bid);

--select distinct(s.sid), s.sname from sailor s,reserves r1, reserves r2 where s.sid=r1.sid and r1.sid=r2.sid and r1.bid !=r2.bid;

--7) 
\qecho 'Question 2.7'
select distinct(r1.sid),r2.sid from reserves r1, reserves r2 
where r1.sid!=r2.sid and r1.bid=r2.bid order by r1.sid;

--8) 
\qecho 'Question 2.8'
select distinct s.sid from sailor s
except 
select distinct r.sid from reserves r where r.day in ('Monday','Tuesday');

--select distinct s.sid from sailor s
--where s.sid not in(select distinct r.sid from reserves r where r.day in ('Monday','Tuesday'));

--9) 
\qecho 'Question 2.9'
select s.sid,b.bid from sailor s, boat b,reserves r 
where b.bid=r.bid and r.sid=s.sid and s.rating>6 and b.color<>'red';

--10) 
\qecho 'Question 2.10'
select b.bid from sailor s, boat b, reserves r 
where b.bid=r.bid and r.sid=s.sid 
and b.bid not in 
(select b1.bid from boat b1, sailor s1, reserves r1 
where s.sid<>s1.sid and b.bid=b1.bid and b1.bid=r1.bid and r1.sid=s1.sid );

--11) 
\qecho 'Question 2.11'
select distinct s.sid from sailor s where sid not in
(select distinct r1.sid from reserves r1, reserves r2, reserves r3 where r1.sid=r2.sid and r2.sid=r3.sid 
and r1.bid <> r2.bid and r2.bid <> r3.bid and r1.bid <> r3.bid);

--select s.sid, count(r.bid) from sailor s  left join reserves r   on s.sid=r.sid group by s.sid
--having count(r.bid)<3

\c postgres;
drop database sp;











