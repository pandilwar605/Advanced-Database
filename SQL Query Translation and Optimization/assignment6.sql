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


\qecho ' '
\qecho 'Part 1'
/*select distinct q(r1)
from 
(
select r1.* from R1 r1 where C1(r1)
intersect
select r2.* from 
(
select r3.* from R3 r3,S1 s1 where C2(s1,r3) and r3.A1=s1.B1
[union | intersect | except]
select r4.* from R4 r4,T1 t1 where C3(t1,r4) and r4.A1=t1.C1
)r2
)q*/


/*select distinct q(r1)
from 
(
select r1.* from R1 r1 where C1(r1)
except 
select r2.* from 
(
select r3.* from R3 r3,S1 s1 where C2(s1,r3) and r3.A1=s1.B1
[union | intersect | except]
select r4.* from R4 r4,T1 t1 where C3(t1,r4) and r4.A1=t1.C1
)r2
)q*/



\qecho ' '
\qecho 'Part 2'
--3)
\qecho ' '
\qecho 'Question 3'

/*explain
select s.sid, s.sname
from student s
where s.sid in (select m.sid from major m where m.major = 'CS') and
exists (select 1
from cites c, book b1, book b2
where (s.sid,c.bookno) in (select t.sid, t.bookno from buys t) and
c.bookno = b1.bookno and c.citedbookno = b2.bookno and
b1.price < b2.price);*/


/*explain
select distinct s.sid, s.sname
from student s 
join major m on (s.sid=m.sid and m.major='CS')
join buys t on (s.sid=t.sid) 
join cites c on (c.bookno=t.bookno)
join book b1 on (c.bookno = b1.bookno) 
join book b2 on(c.citedbookno = b2.bookno and b1.price < b2.price)*/

/*explain 
select distinct s.sid, s.sname
from student s 
join (select m.sid from major m where m.major='CS') p on (s.sid=p.sid)
join (select t.sid,t.bookno from buys t) r on (s.sid=r.sid) 
join (select c.bookno from book b1,cites c, book b2
where c.bookno = b1.bookno and c.citedbookno = b2.bookno and b1.price < b2.price) q
on q.bookno=r.bookno*/


\qecho ' '
\qecho 'Question 4'

/*select distinct s.sid, s.sname, m.major
from student s, major m
where s.sid = m.sid and s.sid not in (select m.sid from major m where m.major = 'CS') and
s.sid <> ALL (select t.sid
from buys t, book b
where t.bookno = b.bookno and b.price < 30) and
s.sid in (select t.sid
from buys t, book b
where t.bookno = b.bookno and b.price < 60);*/

/*
with E1 as
(select distinct s.sid, s.sname, m.major
from student s natural join major m join buys t on (t.sid=s.sid) join book b on (t.bookno = b.bookno and b.price < 60))
(select E1.* from E1
except 
select E1.* from E1 natural join buys t join book b on (t.bookno = b.bookno and b.price < 30)
)
except 
select E1.* from E1 join major m2 on (m2.major='CS' and E1.sid = m2.sid)
*/

\qecho ' '
\qecho 'Question 5'

/*select distinct s.sid, s.sname, b.bookno
from student s, buys t, book b
where s.sid = t.sid and t.bookno = b.bookno and
b.price >= ALL (select b.price
from book b
where (s.sid,b.bookno) in (select t.sid, t.bookno from buys t));*/


/*with E as 
(select distinct s.sid, s.sname, b.bookno, b.price
from student s join buys t on t.sid=s.sid join book b on b.bookno=t.bookno)

select E.sid, E.sname, E.bookno from E
except 
select distinct E.sid, E.sname, E.bookno
from E join buys t1 on (t1.sid=E.sid) join book b1 
on(t1.bookno=b1.bookno and 
not (E.price>=b1.price))*/

\qecho ' '
\qecho 'Question 6'

/*select b.bookno, b.title
from book b
where exists 
(select s.sid
from student s
where s.sid in (select m.sid from major m
where m.major = 'CS'
UNION
select m.sid from major m
where m.major = 'Math') and
s.sid not in (select t.sid
from buys t
where t.bookno = b.bookno));*/

/*with E as
(
select s.sid from student s join major m1 on (m1.major = 'CS' and m1.sid=s.sid)
union
select s.sid from student s join major m2 on (m2.major = 'Math' and m2.sid=s.sid)
)
select distinct b1.bookno,b1.title from book b1 join
( 
select b.bookno,E.sid from book b cross join E
except
select b.bookno, b.sid from buys b
)q2
on b1.bookno=q2.bookno;*/



\qecho ' '
\qecho 'Part 3'

create or replace function makerandomR(m integer, n integer, l integer)
returns void as
$$
declare i integer; j integer;
begin
drop table if exists Ra; drop table if exists Rb;
drop table if exists R;
create table Ra(a int); create table Rb(b int);
create table R(a int, b int);
for i in 1..m loop insert into Ra values(i); end loop;
for j in 1..n loop insert into Rb values(j); end loop;
insert into R select * from Ra a, Rb b order by random() limit(l);
end;
$$ LANGUAGE plpgsql;


create or replace function makerandomS(n integer, l integer)
returns void as
$$
declare i integer;
begin
drop table if exists Sb;
drop table if exists S;
create table Sb(b int);
create table S(b int);
for i in 1..n loop insert into Sb values(i); end loop;
insert into S select * from Sb order by random() limit (l);
end;
$$ LANGUAGE plpgsql;


select makerandomR(3,3,4);
select makerandomS(3,3);


/*explain analyze
select distinct r1.a
from R r1, R r2
where r1.b = r2.a;*/

/*
explain analyze
select distinct r1.a
from R r1 natural join (select distinct r2.a as b from R r2) r2;
*/


\qecho ' '
\qecho 'Question 7'

--Q3
/*explain analyze
select distinct r1.a
from R r1, R r2, R r3
where r1.b = r2.a and r2.b = r3.a;*/

--Q4
/*
explain analyze
select distinct r1.a
from R r1 natural join (select distinct r2.a as b from R r2 natural join (select r3.a as b from R r3) r3) r4;
*/

--select makerandomR(100,100,1000);

\qecho ' '
\qecho 'Question 8'

--Q5
/*explain analyze
select ra.a
from Ra ra
where not exists (select r.b
from R r
where r.a = ra.a and
r.b not in (select s.b from S s));*/

--Q6
/*explain analyze
select ra.a from Ra ra
except 
select q.a from 
(select ra.a,r.b
from R r natural join Ra ra
except
select ra.a,r.b
from Ra ra natural join R r natural join S s)q;*/

/*select makerandomR(1000,1000,100000);
select makerandomS(1000,990);*/

\qecho ' '
\qecho 'Question 9'

--Q7
/*explain analyze
select ra.a
from Ra ra
where not exists (select s.b
from S s
where s.b not in (select r.b
from R r
where r.a = ra.a));*/

--Q8
/*explain analyze
select ra.a
from Ra ra
except 
select q.a from 
(
select ra.a,s.b
from S s cross join Ra ra
except 
select ra.a,s.b
from S s natural join R r natural join Ra ra
)q;*/

/*select makerandomR(100,100,1000) ;
select makerandomS(100,99);*/

\qecho ' '
\qecho 'Question 10'

--Q9
/*explain analyze
with NestedR as (select r.a, array_agg(r.b order by 1) as Bs
from R r
group by (r.a)),
SetS as (select array(select s.b from S s order by 1) as Bs)
select r.a
from NestedR r, SetS s
where r.Bs <@ s.Bs
union
select r.a
from (select a from ra
except
select distinct a from R) r;*/


/*
select makerandomR(1000,1000,100000);
select makerandomS(1000,990);
*/


\qecho ' '
\qecho 'Question 11'


--Q10
/*explain analyze
with NestedR as (select r.a, array_agg(r.b order by 1) as Bs
from R r
group by (r.a)),
SetS as (select array(select s.b from S s order by 1) as Bs)
select r.a
from NestedR r, SetS s
where s.Bs <@ r.Bs;*/

/*select makerandomR(2000,2000,400000);
select makerandomS(2000,1990);*/

\qecho ' '
\qecho 'Part 4'

\qecho ' '
\qecho 'Question 12'

create or replace function setunion(A anyarray, B anyarray) returns anyarray as
$$
with
Aset as (select UNNEST(A)),
Bset as (select UNNEST(B))
select array( (select * from Aset) union (select * from Bset) order by 1);
$$ language sql;


\qecho ' '
\qecho 'Question 12.a'

create or replace function setintersection(A anyarray, B anyarray) returns anyarray as
$$
with
Aset as (select UNNEST(A)),
Bset as (select UNNEST(B))
select array( (select * from Aset) intersect (select * from Bset) order by 1);
$$ language sql;


\qecho ' '
\qecho 'Question 12.b'

create or replace function setdifference(A anyarray, B anyarray) returns anyarray as
$$
with
Aset as (select UNNEST(A)),
Bset as (select UNNEST(B))
select array( (select * from Aset) except (select * from Bset) order by 1);
$$ language sql;

create or replace function isIn(x anyelement, S anyarray)
returns boolean as
$$
select x = SOME(S)
$$ language sql;


\qecho ' '
\qecho 'Question 13'

create or replace view student_books as
select s.sid, array(select t.bookno
from buys t
where t.sid = s.sid order by bookno) as books
from student s order by sid;

select * from student_books;

\qecho ' '
\qecho 'Question 13.a'

create or replace view book_students as 
select b.bookno, array(select t.sid from buys t where t.bookno=b.bookno order by t.sid) as students
from book b order by b.bookno;

select * from book_students;


\qecho ' '
\qecho 'Question 13.b'
create or replace view book_citedbooks as 
select b.bookno, array(select c.citedbookno from cites c where c.bookno=b.bookno order by c.citedbookno) as citedbooks
from book b order by b.bookno;

select * from book_citedbooks;

\qecho ' '
\qecho 'Question 13.c'

create or replace view book_citingbooks as 
select b.bookno, array(select c.bookno from cites c where c.citedbookno=b.bookno order by c.bookno) as citingbooks
from book b order by b.bookno;

select * from book_citingbooks;

\qecho ' '
\qecho 'Question 13.d'

create or replace view major_students as 
select m.major, array_agg(m.sid) as students from major m group by m.major order by m.major;

select * from major_students;

\qecho ' '
\qecho 'Question 13.e'
create or replace view student_majors as
select s.sid, array(select m.major from major m where m.sid=s.sid order by m.major) as majors from student s order by s.sid;

select * from student_majors;

\qecho ' '
\qecho 'Question 14' 

\qecho ' '
\qecho 'Question 14.a'

with E as
(select bookno, unnest(citedbooks) as citedbooks
from book_citedbooks where cardinality(citedbooks)>=3),
F as 
(select e.bookno from E e join book b 
on(e.citedbooks=b.bookno) where b.price<50
group by e.bookno having count(e.bookno)>=3 )
select b.bookno,b.title from F f natural join book b;

/*Alternatively 
with E as
(select bookno, unnest(citedbooks) as citedbooks
from book_citedbooks where cardinality(citedbooks)>=3)

select distinct b.bookno,b.title 
from E e1, E e2, E e3, book b, book b1, book b2, book b3
where e1.bookno=e2.bookno and e2.bookno=e3.bookno  and b.bookno = e1.bookno
and e1.citedbooks <> e2.citedbooks and e2.citedbooks<>e3.citedbooks and e1.citedbooks<>e3.citedbooks 
and b1.bookno=e1.citedbooks and b2.bookno=e2.citedbooks and b3.bookno=e3.citedbooks and b1.price<50 and b2.price<50 and b3.price<50;*/



\qecho ' '
\qecho 'Question 14.b'

with E as
(select unnest(students) as students 
from major_students where major='CS')
select b.bookno, b.title 
from book b natural join book_students bs where
not exists(select 1 from E e where isIn(e.students, bs.students));


\qecho ' '
\qecho 'Question 14.c'

with E as 
(select b.bookno from book b where b.price>=50)
select sb.sid from student_books sb where not exists
(select 1 from E e where not isIn(e.bookno,sb.books));


\qecho ' '
\qecho 'Question 14.d'

select bs.bookno from book_students bs where
not setdifference(bs.students,(select students from major_students where major='CS'))='{}';


\qecho ' '
\qecho 'Question 14.e'

--E is all books who has price more than 45
--F is list of students who bought all books that cost more than 45
with E as 
(select b.bookno from book b where b.price>45),
F as 
(select array_agg(sb.sid)as student_list from student_books sb where not exists
(select 1 from E e where not isIn(e.bookno,sb.books)))
select bs.bookno,b.title from book_students bs natural join book b where
not setdifference(bs.students,(select student_list from F))='{}';


\qecho ' '
\qecho 'Question 14.f'

select distinct sb.sid, bc.bookno 
from student_books sb, book_citingbooks bc
where not(sb.books <@ bc.citingbooks)
order by sb.sid,bc.bookno;

/*Alternatively
select s.sid,b.bookno from student s , book b 
where exists
(
select unnest(books) as books from student_books where sid=s.sid
except
select unnest(citingbooks) as books from book_citingbooks where bookno=b.bookno
);*/



\qecho ' '
\qecho 'Question 14.g'

select * from book s2
select bs1.bookno, bs2.bookno from book_students bs1, book_students bs2
where bs1.students<@ bs2.students and bs2.students<@ bs1.students;

\qecho ' '
\qecho 'Question 14.h'

select bs1.bookno,bs2.bookno from book_students bs1, book_students bs2 
where cardinality(bs1.students)=cardinality(bs2.students);

\qecho ' '
\qecho 'Question 14.i'

select sb.sid from student s natural join student_books sb
where 
(select count(1) from
(
select bo.bookno from book bo
except 
select unnest(sb1.books) from student_books sb1 where sb1.sid=sb.sid 
) c
)=4;



\qecho ' '
\qecho 'Question 14.j' 

--E is list of students who major in psychology
--F is combined number of books bought by the set of students who major in Psychology.
with E as
(select unnest(students) as sid from major_students where major='Psychology'),
F as 
(select count(1) from 
(select e.sid, unnest(sb.books) from student_books sb natural join E e)q)
select sb.sid from student_books sb where cardinality(sb.books) <= (select * from F);

\c postgres;
drop database sp;