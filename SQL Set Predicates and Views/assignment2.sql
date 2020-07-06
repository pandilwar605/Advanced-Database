CREATE DATABASE sp;
--Connecting database 
\c sp; 

\qecho 'Creating Tables'

create table student(sid int primary key, sname text);

create table major(sid int references student(sid), major text, PRIMARY KEY (sid, major));

create table book(bookno int primary key, title text, price int);

create table cites(bookno int references book(bookno), citedbookno int references book(bookno), PRIMARY KEY (bookno, citedbookno));

create table buys(sid int references student(sid), bookno int references book(bookno), PRIMARY KEY (sid, bookno));


\qecho 'Inserting data into Tables'

INSERT INTO student VALUES(1001,'Jean'),(1002,'Maria'),(1003,'Anna'),(1004,'Chin'),(1005,'John'),(1006,'Ryan'),
(1007,'Catherine'),(1008,'Emma'),(1009,'Jan'),(1010,'Linda'),(1011,'Nick'),(1012,'Eric'),(1013,'Lisa'),
(1014,'Filip'),(1015,'Dirk'),(1016,'Mary'),(1017,'Ellen'),(1020,'Ahmed');

INSERT INTO book VALUES(2001,'Databases',40),(2002,'OperatingSystems',25),(2003,'Networks',20),(2004,'AI',45),
(2005,'DiscreteMathematics',20),(2006,'SQL',25),(2007,'ProgrammingLanguages',15),(2008,'DataScience',50),
(2009,'Calculus',10),(2010,'Philosophy',25),(2012,'Geometry',80),(2013,'RealAnalysis',35),(2011,'Anthropology',50),
(3000,'MachineLearning',40);

INSERT INTO buys VALUES(1001,2002),(1001,2007),(1001,2009),(1001,2011),(1001,2013),(1002,2001),(1002,2002),
(1002,2007),(1002,2011),(1002,2012),(1002,2013),(1003,2002),(1003,2007),(1003,2011),(1003,2012),(1003,2013),
(1004,2006),(1004,2007),(1004,2008),(1004,2011),(1004,2012),(1004,2013),(1005,2007),(1005,2011),(1005,2012),
(1005,2013),(1006,2006),(1006,2007),(1006,2008),(1006,2011),(1006,2012),(1006,2013),(1007,2001),(1007,2002),
(1007,2003),(1007,2007),(1007,2008),(1007,2009),(1007,2010),(1007,2011),(1007,2012),(1007,2013),(1008,2007),
(1008,2011),(1008,2012),(1008,2013),(1009,2001),(1009,2002),(1009,2011),(1009,2012),(1009,2013),(1010,2001),
(1010,2002),(1010,2003),(1010,2011),(1010,2012),(1010,2013),(1011,2002),(1011,2011),(1011,2012),(1012,2011),
(1012,2012),(1013,2001),(1013,2011),(1013,2012),(1014,2008),(1014,2011),(1014,2012),(1017,2001),(1017,2002),
(1017,2003),(1017,2008),(1017,2012),(1020,2012);

INSERT INTO cites VALUES(2012,2001),(2008,2011),(2008,2012),(2001,2002),(2001,2007),(2002,2003),(2003,2001),
(2003,2004),(2003,2002),(2012,2005);

INSERT INTO major VALUES(1001,'Math'),(1001,'Physics'),(1002,'CS'),(1002,'Math'),(1003,'Math'),(1004,'CS'),
(1006,'CS'),(1007,'CS'),(1007,'Physics'),(1008,'Physics'),(1009,'Biology'),(1010,'Biology'),(1011,'CS'),
(1011,'Math'),(1012,'CS'),(1013,'CS'),(1013,'Psychology'),(1014,'Theater'),(1017,'Anthropology');


--1)
\qecho 'Question 1'

\qecho ''
\qecho 'a)'
\qecho ''

select distinct s.sid, s.sname from student s, major m, buys bu, book bo
where s.sid=m.sid and bu.sid=s.sid and bo.bookno=bu.bookno
and m.major='CS' and bo.price>10;

\qecho 'b)'

select s.sid,s.sname from student s where s.sid in 
(select m.sid from major m where major='CS' and m.sid in 
(select bu.sid from buys bu where bu.bookno in 
(select bo.bookno from book bo where bo.price>10)
)
);

\qecho 'c)'

select s.sid,s.sname from student s where s.sid =some 
(select m.sid from major m where major='CS' and m.sid = some 
(select bu.sid from buys bu where bu.bookno =some 
(select bo.bookno from book bo where bo.price>10)
)
);


\qecho 'd)'

select s.sid,s.sname from student s where exists
(select m.sid from major m where major='CS' and m.sid = s.sid and exists 
(select bu.sid from buys bu where bu.sid=m.sid and exists 
(select bo.bookno from book bo where bo.price>10)
)
);


--2)
\qecho 'Question 2'

\qecho ''
\qecho 'a)'
\qecho ''

select bo.bookno, bo.title, bo.price  from book bo 
except
select bo.bookno, bo.title, bo.price  from book bo, buys bu, major m
where bo.bookno=bu.bookno and bu.sid=m.sid and m.major='Math';



\qecho 'b)'

select bo.bookno, bo.title, bo.price from book bo where bo.bookno not in
(select bu.bookno from buys bu where bu.sid in 
(select m.sid from major m where m.major='Math'
)
);

\qecho 'c)'
select bo.bookno, bo.title, bo.price from book bo where bo.bookno <> all
(select bu.bookno from buys bu where bu.sid = some
(select m.sid from major m where m.major='Math'
)
);

\qecho 'd)'

select bo.bookno, bo.title, bo.price from book bo where not exists
(select bu.bookno from buys bu where bo.bookno=bu.bookno and  exists
(select m.sid from major m where bu.sid=m.sid and m.major='Math'
)
);

--3)
\qecho 'Question 3'

\qecho ''
\qecho 'a)'
\qecho ''
 
 
select distinct bo.bookno,bo.title,bo.price 
from book bo, cites c1,cites c2,book b1, book b2
where bo.bookno=c1.bookno and bo.bookno=c2.bookno 
and c1.citedbookno <> c2.citedbookno and b1.bookno=c1.citedbookno
and b2.bookno=c2.citedbookno and b1.price<60 and b2.price<60;

\qecho 'b)'

select bo.bookno,bo.title,bo.price 
from book bo where bo.bookno in 
(select c1.bookno from cites c1,book b1 
where b1.price<60 and b1.bookno=c1.citedbookno and c1.bookno in
(select c2.bookno from cites c2,book b2 
where b2.price<60 and b2.bookno=c2.citedbookno 
and c1.citedbookno<>c2.citedbookno
)
);


\qecho 'c)'

select bo.bookno,bo.title,bo.price 
from book bo where exists 
(select c1.bookno from cites c1,book b1 
where bo.bookno=c1.bookno and b1.price<60 and b1.bookno=c1.citedbookno 
and exists
(select c2.bookno from cites c2,book b2 
where c1.bookno=c2.bookno and b2.price<60 and b2.bookno=c2.citedbookno 
and c1.citedbookno<>c2.citedbookno
)
);

--4)
\qecho 'Question 4'

\qecho ''
\qecho 'a)'
\qecho ''

select distinct s.sid,s.sname,bo.title,bo.price 
from student s, buys bu, book bo
where s.sid=bu.sid and bo.bookno=bu.bookno  
and not exists
(select bu.sid from buys bu1, book bo1
where s.sid=bu1.sid and bo1.bookno=bu1.bookno 
and bo1.price>bo.price);

\qecho 'b)'

select distinct s.sid,s.sname,bo.title,bo.price 
from student s, buys bu, book bo
where s.sid=bu.sid and bo.bookno=bu.bookno 
and bo.price>=all
(select bo1.price from buys bu1, book bo1
where s.sid=bu1.sid and bo1.bookno=bu1.bookno);


--5)
\qecho 'Question 5'

select s.sid, s.sname from student s
where s.sid not in (select distinct bu.sid from buys bu)

union 

select distinct s.sid,s.sname
from student s, buys bu1, book b1
where s.sid=bu1.sid and b1.bookno=bu1.bookno
and b1.price>20  and 
s.sid not in
(select bu2.sid from buys bu2, book b2 where b2.bookno=bu2.bookno
and b2.price>20 and bu2.bookno <> bu1.bookno);


--6)
\qecho 'Question 6'

/*select * into tem from 
(select b.bookno , b.title,b.price from book b 
except
select b.bookno,b.title,b.price from book b
where not exists 
(select b1.bookno from book b1 where b1.price>b.price)
) as tem
select distinct b2.bookno, b2.title,b2.price from tem b2,
tem
where not exists
(select tem.bookno from tem where tem.price>b2.price );*/

select b.bookno, b.title,b.price from book b where exists(
select * from book b1 where b.price < b1.price) and not exists (
select * from book b2, book b3 where b.price < b2.price and b2.price < b3.price);



--7)
\qecho 'Question 7'

select distinct b.bookno,b.title,b.price from book b,cites c
where b.bookno=c.bookno  and c.citedbookno not in(
select b.bookno from book b
where not exists 
(select b1.bookno from book b1 where b1.price>b.price));


--8)
\qecho 'Question 8'

select s.sid,s.sname from student s, major m1
where s.sid=m1.sid  and not exists
(select 1 from  major m2 
where m1.sid=m2.sid and m1.major <> m2.major)
and not exists
(select bu.bookno from buys bu, book bo 
where s.sid=bu.sid and bu.bookno=bo.bookno and bo.price<40);


--9)
\qecho 'Question 9'
/*select bo.bookno, bo.title from book bo
where bo.bookno =all(
select bu1.bookno from buys bu1
where bu1.sid in
(
select distinct s1.sid from student s1, major m1 
where s1.sid=m1.sid and m1.major='Math'
intersect
select distinct s2.sid from student s2, major m2 
where s2.sid=m2.sid and m2.major='CS'
))*/

select distinct bo.bookno, bo.title
from book bo
where not exists ( 
(select m1.sid from major m1, major m2 where m1.major='Math' and m2.major='CS' and m1.sid=m2.sid)
except
(select b1.sid FROM buys b1 WHERE b1.bookno=bo.bookno));



--10)
\qecho 'Question 10'

select s.sid, s.sname
from student s
where not exists(
select 1 from buys y1, book b1
where y1.bookno=b1.bookno and y1.sid=s.sid and b1.price > 70)
	
union

select s.sid, s.sname
from student s
where exists(
select 1 from buys y1, book b1
where y1.bookno=b1.bookno and y1.sid=s.sid and b1.price >= 70 and 
exists(
select 1 from buys y2, book b2
where y2.bookno=b2.bookno and y2.sid=s.sid and b2.price <= 30));


--11)
\qecho 'Question 11'

select distinct s1.sid, s2.sid from student s1, student s2,major m1
where s1.sid<>s2.sid and s1.sid=m1.sid 
and exists(select 1 from major m2 where m2.sid=s2.sid and m1.major=m2.major)

intersect

select distinct bu1.sid,bu2.sid 
from buys bu1, buys bu2
where bu1.sid <> bu2.sid
and bu1.bookno not in 
(select bookno from buys b where bu1.sid <> b.sid and b.sid=bu2.sid)
or bu2.bookno not in 
(select bookno from buys b where bu2.sid <> b.sid and b.sid=bu1.sid); 

--12)
\qecho 'Question 12'

select count(t) from
(
select distinct s1.sid, b1.bookno, s2.sid, b2.bookno
from student s1, book b1, student s2, book b2
where b1.bookno not in 
(select b3.bookno from buys b3 where b3.sid=s1.sid and b3.bookno=b1.bookno)
and b2.bookno not in 
(select b4.bookno from buys b4 where b4.sid=s2.sid and b4.bookno=b2.bookno)
	
union
select distinct s1.sid, b1.bookno, s2.sid, b2.bookno
from student s1, book b1, student s2, book b2
where b1.bookno in 
(select b3.bookno from buys b3 where b3.sid=s1.sid and b3.bookno=b1.bookno)
and b2.bookno not in 
(select b4.bookno from buys b4 where b4.sid=s2.sid and b4.bookno=b2.bookno)

union 

select distinct s1.sid, b1.bookno, s2.sid, b2.bookno
from student s1, book b1, student s2, book b2
where b1.bookno not in 
(select b3.bookno from buys b3 where b3.sid=s1.sid and b3.bookno=b1.bookno)
and b2.bookno in 
(select b4.bookno from buys b4 where b4.sid=s2.sid and b4.bookno=b2.bookno)
)t;


--13)
\qecho 'Question 13'

create view bookAtLeast30 as
select b.bookno,b.title,b.price from book b where b.price>=30;

select s.sid, s.sname from student s
where s.sid not in (select distinct bu.sid from buys bu, book b1 where b1.bookno=bu.bookno and b1.price<30)
union 
select distinct s.sid, s.sname from student s, buys bu1,
(select * from book 
except
select * from bookatleast30) as b1 
where s.sid=bu1.sid and bu1.bookno=b1.bookno and 
not exists (select 1 from buys bu2,
(select * from book 
except
select * from bookatleast30) as b2 
where s.sid=bu2.sid and bu2.bookno=b2.bookno and bu1.bookno<>bu2.bookno);


drop view bookAtLeast30;


--14)
\qecho 'Question 14'

with bookAtLeast30 as(select b.bookno,b.title,b.price from book b where b.price>=30)

select s.sid, s.sname from student s
where s.sid not in (select distinct bu.sid from buys bu, book b1 where b1.bookno=bu.bookno and b1.price<30)
union 
select distinct s.sid, s.sname from student s, buys bu1,
(select * from book 
except
select * from bookatleast30) as b1 
where s.sid=bu1.sid and bu1.bookno=b1.bookno and 
not exists (select 1 from buys bu2,
(select * from book 
except
select * from bookatleast30) as b2 
where s.sid=bu2.sid and bu2.bookno=b2.bookno and bu1.bookno<>bu2.bookno);


--15)
\qecho 'Question 15'
\qecho 'Function Created'
create function citesBooks(b int4)
returns table(bookno int, title text, price int) as 
$$
select bo.bookno,bo.title,bo.price from book bo, cites c
where c.citedbookno=b and c.bookno=bo.bookno;
$$ language sql;


\qecho 'Question 15 a)'

select distinct b.bookno,b.title from book b,cites c,book b1
where b.bookno in (select c.bookno from citesbooks(2001) c)
and b1.bookno=c.citedbookno
and b1.price<50;

--select b.bookno,c.bookno,c.citedbookno, b.title,b.price, b1.price
--from book b, cites c, book b1
--where b.bookno=c.bookno and b1.bookno=c.citedbookno
--and b.bookno in (2003,2012)


\qecho 'Question 15 b)'

select distinct b.bookno,b.title from book b, book b2 where b.bookno in (
select distinct x.bookno from 
(select c1.bookno,c1.citedbookno from cites c1 where c1.bookno in (select c.bookno from citesbooks(b2.bookno) c)) x,
(select c1.bookno,c1.citedbookno from cites c1 where c1.bookno in (select c.bookno from citesbooks(b2.bookno) c)) y
where x.bookno=y.bookno and x.citedbookno<>y.citedbookno
);

\c postgres;
drop database sp;