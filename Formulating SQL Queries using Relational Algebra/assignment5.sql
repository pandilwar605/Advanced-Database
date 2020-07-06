CREATE DATABASE sp;
--Connecting database 
\c sp; 

\qecho 'Creating Tables'

create table cites(bookno int, citedbookno int);
create table book(bookno int, title text, price int);
create table student(sid int, sname text);
create table major(sid int, major text);
create table buys(sid int, bookno int);

\qecho 'Inserting data into tables'

-- Data for the student relation.
INSERT INTO student VALUES(1001,'Jean'),(1002,'Maria'),(1003,'Anna'),(1004,'Chin'),
(1005,'John'),(1006,'Ryan'),(1007,'Catherine'),(1008,'Emma'),(1009,'Jan'),(1010,'Linda'),
(1011,'Nick'),(1012,'Eric'),(1013,'Lisa'),(1014,'Filip'),(1015,'Dirk'),(1016,'Mary'),(1017,'Ellen'),(1020,'Ahmed');

-- Data for the book relation.
INSERT INTO book VALUES(2001,'Databases',40),(2002,'OperatingSystems',25),(2003,'Networks',20),
(2004,'AI',45),(2005,'DiscreteMathematics',20),(2006,'SQL',25),(2007,'ProgrammingLanguages',15),
(2008,'DataScience',50),(2009,'Calculus',10),(2010,'Philosophy',25),(2012,'Geometry',80),
(2013,'RealAnalysis',35),(2011,'Anthropology',50),(3000,'MachineLearning',40);

-- Data for the buys relation.

INSERT INTO buys VALUES(1001,2002),(1001,2007),(1001,2009),(1001,2011),(1001,2013),
(1002,2001),(1002,2002),(1002,2007),(1002,2011),(1002,2012),(1002,2013),(1003,2002),
(1003,2007),(1003,2011),(1003,2012),(1003,2013),(1004,2006),(1004,2007),(1004,2008),
(1004,2011),(1004,2012),(1004,2013),(1005,2007),(1005,2011),(1005,2012),(1005,2013),
(1006,2006),(1006,2007),(1006,2008),(1006,2011),(1006,2012),(1006,2013),(1007,2001),
(1007,2002),(1007,2003),(1007,2007),(1007,2008),(1007,2009),(1007,2010),(1007,2011),
(1007,2012),(1007,2013),(1008,2007),(1008,2011),(1008,2012),(1008,2013),(1009,2001),
(1009,2002),(1009,2011),(1009,2012),(1009,2013),(1010,2001),(1010,2002),(1010,2003),
(1010,2011),(1010,2012),(1010,2013),(1011,2002),(1011,2011),(1011,2012),(1012,2011),
(1012,2012),(1013,2001),(1013,2011),(1013,2012),(1014,2008),(1014,2011),(1014,2012),
(1017,2001),(1017,2002),(1017,2003),(1017,2008),(1017,2012),(1020,2012);

-- Data for the cites relation.
INSERT INTO cites VALUES(2012,2001),(2008,2011),(2008,2012),(2001,2002),(2001,2007),
(2002,2003),(2003,2001),(2003,2004),(2003,2002),(2012,2005);


-- Data for the major relation.

INSERT INTO major VALUES(1001,'Math'),(1001,'Physics'),(1002,'CS'),(1002,'Math'),
(1003,'Math'),(1004,'CS'),(1006,'CS'),(1007,'CS'),(1007,'Physics'),(1008,'Physics'),
(1009,'Biology'),(1010,'Biology'),(1011,'CS'),(1011,'Math'),(1012,'CS'),(1013,'CS'),
(1013,'Psychology'),(1014,'Theater'),(1017,'Anthropology');

\qecho ''
\qecho 'Question 1 a)'
--Reference: Discussed with one of the colleagues(Neha Pai)
with book_sid_relation as 
(select b.bookno, s.sid
from (select sid from major where major='CS') s cross join book b
except
select b.bookno, s.sid
from (select sid from major where major='CS') s natural join buys b)

select b1.bookno from book_sid_relation b1 join book_sid_relation b2 on b1.bookno = b2.bookno and b1.sid <> b2.sid
except
select b1.bookno from book_sid_relation b1 
join book_sid_relation b2 on b1.bookno = b2.bookno and b1.sid <> b2.sid 
join book_sid_relation b3 on b1.bookno=b3.bookno and b1.sid<>b3.sid and b2.sid<>b3.sid;

\qecho 'Question 7'

--select s.sid,s.sname from student s where s.sid in 
--(select m.sid from major m where major='CS' and m.sid in 
--(select bu.sid from buys bu where bu.bookno in 
--(select bo.bookno from book bo where bo.price>10)));

with e1 as (select sid from buys natural join (select bookno from book where price>10) q),
e2 as (select m.sid from major m join e1 on (m.sid = e1.sid and m.major='CS'))
select distinct sid,sname from student natural join e2;

\qecho 'Question 8'

--select distinct bo.bookno,bo.title,bo.price 
--from book bo, cites c1,cites c2,book b1, book b2
--where bo.bookno=c1.bookno and bo.bookno=c2.bookno 
--and c1.citedbookno <> c2.citedbookno and b1.bookno=c1.citedbookno
--and b2.bookno=c2.citedbookno and b1.price<60 and b2.price<60;

with e1 as (select c.bookno, c.citedbookno,b.title,b.price from cites c join book b on (b.bookno = c.citedbookno and b.price<60))
select distinct c.bookno,c.title,c.price 
from e1 a join e1 b on a.bookno=b.bookno and a.citedbookno<>b.citedbookno join book c on c.bookno=a.bookno;


\qecho 'Question 9'

select b.bookno,b.price,b.title from book b
except
select b.bookno,b.price,b.title from book b natural join buys t natural join (select m.sid from major m where m.major='Math') e1;

\qecho 'Question 10'

--select distinct s.sid,s.sname,bo.title,bo.price 
--from student s, buys bu, book bo
--where s.sid=bu.sid and bo.bookno=bu.bookno 
--and bo.price>=all
--(select bo1.price from buys bu1, book bo1
--where s.sid=bu1.sid and bo1.bookno=bu1.bookno);

with e1 as
(select distinct s.sid,s.sname,bo.title,bo.price 
from student s natural join buys bu natural join book bo
)
select distinct e.sid,e.sname,e.title,e.price from e1 e
except
select distinct e.sid,e.sname,e.title,e.price 
from e1 e cross join buys bu1 cross join book bo1
where e.sid=bu1.sid and bo1.bookno=bu1.bookno
and not (e.price>=bo1.price);


\qecho 'Question 11'


--select b.bookno, b.title,b.price from book b where exists(
--select * from book b1 where b.price < b1.price) and not exists (
--select * from book b2, book b3 where b.price < b2.price and b2.price < b3.price);

with E as
(select b.*
from book b join book b1 on b.price < b1.price)
select bookno, title
from E
except
select e.bookno, e.title
from E e join E e1 on e.price < e1.price;

\qecho 'Question 12'

--select distinct b.bookno,b.title,b.price from book b,cites c
--where b.bookno=c.bookno  and c.citedbookno not in(
--select b.bookno from book b
--where not exists 
--(select b1.bookno from book b1 where b1.price>b.price));

with E1 as 
(select distinct b.bookno,b.title,b.price,c.citedbookno from book b natural join cites c)
select q1.bookno,q1.title,q1.price from
(select distinct e1.bookno,e1.title,e1.price from E1 e1
except 
select q.* from 
(select distinct e2.bookno,e2.title,e2.price from E1 e2 join book b on b.bookno=e2.citedbookno 
except 
select distinct e3.bookno,e3.title,e3.price from E1 e3 join book b on b.bookno=e3.citedbookno 
join book b1 on b1.price > b.price)q)q1;



\qecho 'Question 13'

--select s.sid,s.sname from student s, major m1
--where s.sid=m1.sid  and not exists
--(select 1 from  major m2 
--where m1.sid=m2.sid and m1.major <> m2.major)
--and not exists
--(select bu.bookno from buys bu, book bo 
--where s.sid=bu.sid and bu.bookno=bo.bookno and bo.price<40);

with E as
(select s.sid,s.sname,m.major from student s join major m
on s.sid=m.sid)
select e.sid,e.sname from E e
except 
select e.sid,e.sname from  E e join major m2 on e.sid=m2.sid and e.major <> m2.major
except 
select e.sid,e.sname from E e join buys bu on e.sid=bu.sid join book bo on bu.bookno=bo.bookno
and bo.price<40;


\qecho 'Question 14'

with E as (select m1.sid from major m1 join major m2 on m1.major='Math' and m2.major='CS' and m1.sid=m2.sid)
select b1.bookno,b1.title from book b1 join
(select t.bookno from buys t
except
(select q1.bookno from 
(select * from book b cross join E
except
select * from book b natural join buys)q1)
)q2
on b1.bookno=q2.bookno;

\qecho 'Question 15'

--select s.sid, s.sname
--from student s
--where not exists(
--select 1 from buys y1, book b1
--where y1.bookno=b1.bookno and y1.sid=s.sid and b1.price > 70)
--union
--select s.sid, s.sname
--from student s
--where exists(
--select 1 from buys y1, book b1
--where y1.bookno=b1.bookno and y1.sid=s.sid and b1.price >= 70 and 
--exists(
--select 1 from buys y2, book b2
--where y2.bookno=b2.bookno and y2.sid=s.sid and b2.price <= 30));

select s.sid, s.sname
from student s
except 
select s1.sid, s1.sname from buys t1 join book b1 on t1.bookno=b1.bookno and b1.price > 70 join student s1 on t1.sid=s1.sid
union
select distinct s2.sid, s2.sname
from student s2 join buys t2 on t2.sid=s2.sid join book b2 on t2.bookno=b2.bookno and b2.price >= 70 
join buys t3 on t3.sid=s2.sid join book b3 on t3.bookno=b3.bookno and b3.price <= 30;


\qecho 'Question 16'


with E as (select m1.sid,m2.sid
from major m1 join major m2
on m1.major = m2.major and m1.sid<>m2.sid),
E1 as 
(select t1.sid as sid1, t1.bookno, s.sid as sid2
from buys t1 cross join Student s),
E2 as 
(select s.sid as sid1, t2.bookno, t2.sid as sid2
from Student s cross join buys t2)

select * from E

intersect

(select distinct sid1, sid2
from 
(select e1.* from E1 e1
except
select e2.* from E2 e2) q1

union 

select distinct sid1, sid2
from 
(select e2.* from E2 e2
except
select e1.* from E1 e1) q2
);


\c postgres;
drop database sp;
