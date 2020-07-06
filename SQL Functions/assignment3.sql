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

insert into student values (1021, 'Kris');

insert into major values (1021, 'CS'), (1021, 'Math');

insert into book values (4001, 'LinearAlgebra', 30),(4002, 'MeasureTheory', 75),
   (4003, 'OptimizationTheory', 30);

insert into buys values (1001,3000),(1001,2004),(1021, 2001),(1021, 2002),(1021, 2003),(1021, 2004),(1021, 2005),(1021, 2006),
   (1021, 2007),(1021, 2008),(1021, 2009),(1021, 2010),(1021, 2011),(1021, 4003),(1021, 4001),(1021, 4002),(1015, 2001),(1015, 2002),
   (1016, 2001),(1016, 2002),(1015, 2004),(1015, 2008),(1015, 2012),(1015, 2011),(1015, 3000),(1016, 2004),(1016, 2008),(1016, 2012),
   (1016, 2011),(1016, 3000),(1002, 4003),(1011, 4003),(1015, 4003),(1015, 4001),(1015, 4002),(1016, 4001),(1016, 4002);
  

\qecho ''
\qecho 'Part - I'

--1)
\qecho 'Question 1'

\qecho ''
\qecho 'a)'
\qecho ''

create table relation_a
(a int);
insert into relation_a
values(1),(2),(3);


create table relation_b
(b int);
insert into relation_b
values(1),(3);


select not exists(select a from relation_a except select b from relation_b) as empty_a_minus_b,
not exists(select b from relation_b except select a from relation_a) as empty_b_minus_a,
not exists(select a from relation_a intersect select b from relation_b) as empty_a_intersection_b;

\qecho 'b)'

select not exists(select a from relation_a where a not in (select b from relation_b)) as empty_a_minus_b,
not exists(select b from relation_b where b not in(select a from relation_a)) as empty_b_minus_a,
not exists(select a from relation_a where a in(select b from relation_b)) as empty_a_intersection_b;

drop table relation_a;
drop table relation_b;


--2)
\qecho ''
\qecho 'Question 2'

create table boolean_vars
(val bool);
insert into boolean_vars
values(True),(False),(null);

select p.val as p,q.val as q, r.val as r, (not (not p.val or q.val) or not r.val) as value
from boolean_vars p, boolean_vars q, boolean_vars r;

drop table boolean_vars;

--3)
\qecho ''
\qecho 'Question 3'

create table point
(
pid int,
x float,
y float
);

insert into point values
(1,0,0),(2,0,1),(3,1,0);

\qecho ''
\qecho 'a)'
\qecho ''

create function find_distance(x1 float,y1 float, x2 float,y2 float)
returns float as
$$
select sqrt(power(x1-x2,2) + power(y1-y2,2))
$$ language sql;


select p1.pid,p2.pid
from point p1,point p2
where 
p1.pid<>p2.pid and
find_distance(p1.x,p1.y,p2.x,p2.y)<
(select max(find_distance(p1.x,p1.y,p2.x,p2.y)) from point p1, point p2);
 

\qecho 'b)'
create table check_collinear
(
pid int,
x float,
y float
);
insert into check_collinear values
(0,0,0),(1,1,1),(2,2,2);

select p1.pid,p2.pid,p3.pid
from check_collinear p1, check_collinear p2, check_collinear p3
where
p1.pid<>p2.pid and p2.pid<>p3.pid and p3.pid<>p1.pid and 
((find_distance(p1.x,p1.y,p2.x,p2.y) = find_distance(p1.x,p1.y,p3.x,p3.y) + find_distance(p3.x,p3.y,p2.x,p2.y))
or
(find_distance(p1.x,p1.y,p3.x,p3.y) = find_distance(p1.x,p1.y,p2.x,p2.y) + find_distance(p2.x,p2.y,p3.x,p3.y))
or
(find_distance(p2.x,p2.y,p3.x,p3.y) = find_distance(p2.x,p2.y,p1.x,p1.y) + find_distance(p1.x,p1.y,p3.x,p3.y)));
--Using 3 or conditions will print all the combinations of collinear points 

drop table point;
drop table check_collinear;
drop function find_distance;

--4)
\qecho ''
\qecho 'Question 4'

create table r(
a int,
b int,
c int);

insert into r values (1,1,1),(2,2,2),(3,3,3);
insert into r values (1,2,3);

\qecho ''
\qecho 'a)'
\qecho ''

select not exists
(select * from r r1 , r r2 
where r1.a=r2.a and (r1.b<>r2.b or r1.c<>r2.c)) as IsKey;

--Alternate Queries
--select not exists(select * from r r1,r r2 where r1.a=r2.a and r1.b<>r2.b )
--and not exists(select * from r r1,r r2 where r1.a=r2.a and r1.c<>r2.c)
--as isKey
--
--select not exists
--(select * from r r1, r r2 where r1.a=r2.a and r1.b<>r2.b  
--union 
--select * from r r1, r r2 where r1.a=r2.a and r1.c<>r2.c) as IsKey;

\qecho 'b)'

create table primary_key_relation_of_A(
a int,
b int,
c int);
insert into primary_key_relation_of_A values (1,1,1),(2,2,2),(3,3,3);
select * from primary_key_relation_of_A;

select not exists
(select * from primary_key_relation_of_A r1 , primary_key_relation_of_A r2 
where r1.a=r2.a and (r1.b<>r2.b or r1.c<>r2.c)) as IsKey;

create table non_primary_key_relation_of_A(
a int,
b int,
c int);

insert into non_primary_key_relation_of_A values (1,1,1),(2,2,2),(3,3,3);
insert into non_primary_key_relation_of_A values (1,14,16);
select * from non_primary_key_relation_of_A;

select not exists
(select * from non_primary_key_relation_of_A r1 , non_primary_key_relation_of_A r2 
where r1.a=r2.a and (r1.b<>r2.b or r1.c<>r2.c)) as IsKey;


drop table r;
drop table primary_key_relation_of_A;
drop table non_primary_key_relation_of_A;

\qecho ''
\qecho 'Part II'

--5)
\qecho ''
\qecho 'Question 5'

create table mat
(
ro int,
col int,
val int
);

insert into mat values 
(1,1,1),
(1,2,2),
(1,3,3),
(2,1,1),
(2,2,-3),
(2,3,5),
(3,1,4),
(3,2,0),
(3,3,-2);

with matrix as 
(
select m1.ro,m2.col,sum(m1.val*m2.val) as val from mat m1, mat m2  
where m1.col=m2.ro
group by m1.ro,m2.col
)
select m3.ro,m4.col, sum(m3.val * m4.val) as val from matrix m3,matrix m4
where m3.col=m4.ro
group by m3.ro,m4.col;


drop table mat;

--6)
\qecho ''
\qecho 'Question 6'

with temp_relation_A as (
select b.price from book b)
select (price % 4) as mod_column, count(price) count_of_elements
from temp_relation_A 
group by price % 4;

--7)
\qecho ''
\qecho 'Question 7'

--Assuming cites is a unary relation A, group by can give distinct values
select bookno from cites 
group by bookno;

--8)
\qecho ''
\qecho 'Question 8'

\qecho 'a)'

select bo.bookno,bo.title from book bo 
where bo.bookno in (
select b.bookno from book b, buys bu, student s, major m 
where b.bookno=bu.bookno and bu.sid=s.sid and s.sid=m.sid
and m.major='CS' and b.price<40
group by b.bookno
having count(b.bookno)<3
);

\qecho 'b)'

select s1.sid,s1.sname,t.cnt from 
student s1,(select s.sid, count(bu.bookno) as cnt from student s , book bo, buys bu
where s.sid=bu.sid and bu.bookno= bo.bookno
group by s.sid
having sum(bo.price)<200) as t
where s1.sid=t.sid;

\qecho 'c)'

select s.sid, s.sname from student s
where s.sid in
(select s1.sid from student s1, buys bu1, book bo1 where
s1.sid=bu1.sid and bu1.bookno=bo1.bookno
group by s1.sid
having 
sum(bo1.price)>=all
(select sum(bo2.price) from student s2,book bo2, buys bu2
where bo2.bookno=bu2.bookno and s2.sid=bu2.sid group by s2.sid )
);


\qecho 'd)'

select m.major,sum(bo.price) from student s, major m, book bo, buys bu
where s.sid=m.sid and bo.bookno=bu.bookno and bu.sid=s.sid
group by m.major;

\qecho 'e)'

with title_count as
(select bo.bookno, count(s.sid) as cnt from student s, major m, book bo, buys bu
where s.sid=m.sid and bo.bookno=bu.bookno and bu.sid=s.sid and m.major='CS'
group by bo.bookno)
select b1.bookno,b2.bookno from  title_count b1, title_count b2
where b1.cnt=b2.cnt and b1.bookno<> b2.bookno;

\qecho ''
\qecho 'Part III'
--9)
\qecho 'Question 9'

create or replace view stud as
select distinct s.sid,s.sname,bu.bookno from student s, buys bu
where bu.sid=s.sid;

create function costMoreThan(c int4)
returns table(sid int,bookno int) as 
$$
select bu.sid,bu.bookno from buys bu, book bo
where bu.bookno=bo.bookno and bo.price>c
$$ language sql;

select distinct a1.sid,a1.sname from stud a1 
where exists
(select b.bookno from costMoreThan(50) b 
except 
select a.bookno from stud a, costMoreThan(50) b where a.sid=a1.sid and b.sid=a.sid);

drop view stud;
DROP FUNCTION costMoreThan("int4");


--10)
\qecho ''
\qecho 'Question 10'

create or replace view booksBoughtbyStudents as
select s.sid,b.bookno,b.title from student s, book b, buys bu
where s.sid=bu.sid and bu.bookno = b.bookno;

create function studentMajorin(mj text)
returns table(sid int) as 
$$
select m.sid from student s, major m
where m.sid=s.sid and m.major=mj
$$ language sql;


select distinct a1.bookno,a1.title from booksBoughtbyStudents a1
where exists
(select a.sid from booksBoughtbyStudents a where a.sid=a1.sid
except(
select b1.sid from studentMajorin('CS') b1 
union
select b2.sid from studentMajorin('Math') b2
)
);

drop view booksBoughtbyStudents;
DROP FUNCTION public.studentmajorin("text");


--11)
\qecho ''
\qecho 'Question 11'

create or replace view leastExpensiveBook as (select b.bookno from book
b where b.price = (select min(b1.price) from book b1));


select distinct s1.sid, s1.sname from student s1
where s1.sid not in 
(
select distinct s.sid from student s, buys bu, book bo 
where s.sid=bu.sid and bo.bookno=bu.bookno
and bo.bookno in (
select c.bookno from leastExpensiveBook c)
);

drop view leastExpensiveBook;


--12)
\qecho ''
\qecho 'Question 12'

create or replace view bookbycs as
(select b.bookno, m.sid from book b, buys bu, major m 
where b.bookno=bu.bookno and m.sid=bu.sid and m.major='CS');

--2 not exists statements are to check a-b and b-a is empty i.e. a=b
select distinct a.bookno, b.bookno 
from bookbycs a, bookbycs b
where 
not exists
(select c.sid from bookbycs c where c.bookno=a.bookno
except 
select d.sid from bookbycs d where d.bookno=b.bookno)
and not exists
(select e.sid from bookbycs e where e.bookno=b.bookno
except 
select f.sid from bookbycs f where f.bookno=a.bookno)
and a.bookno<>b.bookno;

drop view bookbycs;

\qecho ''
\qecho 'Part IV'
--13)
\qecho ''
\qecho 'Question 13'

create or replace view cs_student as
select s.sid,s.sname,bu.bookno from student s,major m,buys bu
where m.sid=s.sid and m.major='CS' and bu.sid=s.sid;

create function costLessThan(c int4)
returns table(sid int,bookno int) as 
$$
select bu.sid, bu.bookno from buys bu, book bo
where bu.bookno=bo.bookno and bo.price<c
$$ language sql;

select distinct c.sid,c.sname from cs_student c
where 
(select count(1) from 
(select a.bookno from cs_student a where a.sid=c.sid
intersect
select b.bookno from costLessThan(50) b where b.sid=c.sid) d)<4;

drop view cs_student;
DROP FUNCTION costLessThan("int4");

--14)
\qecho ''
\qecho 'Question 14'

--Alternate Query
--select b.bookno,b.title from book b where
--b.bookno in (
--select bu.bookno from buys bu, major m
--where m.sid=bu.sid and m.major='CS'
--group by bu.bookno
--having count(m.sid)%2=1
--);

create function cs_students_for_book(b int4)
returns table(sid int) as 
$$
select bu.sid from buys bu,major m
where bu.bookno=b and m.sid=bu.sid and m.major='CS'
$$ language sql;

select a.bookno,a.title from book a
where 
(select count(1) from
(
select b.sid from cs_students_for_book(a.bookno) b
) c
)%2=1;

drop function cs_students_for_book;

--15)
\qecho ''
\qecho 'Question 15'

create function books_for_student(b int4)
returns table(bookno int) as 
$$
select bu.bookno as cnt from buys bu, student s
where s.sid=bu.sid and s.sid=b
$$ language sql;


select s.sid,s.sname from student s 
where 
(select count(1) from
(
select bo.bookno from book bo
except 
select b.bookno from books_for_student(s.sid) b
) c
)=3;

drop function books_for_student;


--16)
\qecho ''
\qecho 'Question 16'

create function student_bought_book(b int4)
returns table(sid int) as 
$$
select s.sid from student s, buys bu
where s.sid=bu.sid and bu.bookno=b
$$ language sql;

select b1.bookno,b2.bookno from book b1, book b2
where b1.bookno<> b2.bookno
and  
(select count(1) from
(
select a.sid from student_bought_book(b1.bookno) a
except 
select b.sid from student_bought_book(b2.bookno) b
)c
)=0;

drop function student_bought_book;


\c postgres;
drop database sp;