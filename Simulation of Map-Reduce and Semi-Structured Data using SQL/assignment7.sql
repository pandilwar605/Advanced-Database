CREATE DATABASE sp;
--Connecting database 
\c sp; 

\qecho 'Creating Tables'

\qecho ' '
\qecho 'Part 1'

create table document (doc text, words text[]);

insert into document values ('d1', '{"A","B","C"}');
insert into document values ('d2', '{"B","C","D"}');
insert into document values ('d3', '{"A","E"}');
insert into document values ('d4', '{"B","B","A","D"}');
insert into document values ('d5', '{"E","F"}');

table document;


\qecho ' '
\qecho 'Q.1'
--1

\qecho ' '

\qecho 'Question 1.a'

create table R (a int, b int, c int);
insert into R values (1,2,3), (4,5,6), (1,2,4);

\qecho 'Relation R'
table R;

create table encodingofR (key text, value jsonb);

insert into encodingofR select 'R' as Key, json_build_object('a', r.a, 'b', r.b, 'c', r.c)::jsonb as Value
                        from   R r;

\qecho 'Relation encodingofR'
table encodingofR;

-- Map function
--drop function if exists mapper;
CREATE OR REPLACE FUNCTION mapper(KeyIn text, ValueIn jsonb)
RETURNS TABLE(KeyOut jsonb, ValueOut text) AS
$$
    SELECT json_build_object('a', ValueIn->'a', 'b', ValueIn->'b')::jsonb, KeyIn;
$$ LANGUAGE SQL;

-- Reduce function
--drop function if exists reducer;
CREATE OR REPLACE FUNCTION reducer(KeyIn jsonb, ValuesIn text[])
RETURNS TABLE(KeyOut jsonb, ValueOut jsonb) AS
$$
    SELECT KeyIn->'a',KeyIn->'b';
$$ LANGUAGE SQL;

with
-- mapper phase
Map_Phase AS (
    SELECT m.KeyOut, m.ValueOut 
    FROM   encodingofR r, LATERAL(SELECT q.KeyOut, q.ValueOut FROM mapper(r.key, r.value)q)m
),
--select * from Map_Phase
-- group phase
Group_Phase AS (
    SELECT KeyOut, array_agg(Valueout) as ValueOut
    FROM   Map_Phase
    GROUP  BY (KeyOut)
),
--select * from group_phase
-- reducer phase
Reduce_Phase AS (
    SELECT r.KeyOut as a, r.ValueOut as b
    FROM   Group_Phase gp, LATERAL(SELECT r.KeyOut, r.ValueOut FROM Reducer(gp.KeyOut, gp.ValueOut) r) r
)
SELECT * FROM Reduce_Phase;



\qecho ' '
\qecho 'Question 1.b'
drop table if exists R; 
--drop table if exists S;

create table R(a int); 
create table S(a int);

insert into R values (1),(2),(3),(4);
insert into S values (2),(4),(5);

\qecho 'Relation R'
table R;

\qecho 'Relation S'
table S;

--drop table if exists EncodingOfRandS;
create table EncodingOfRandS(key text, value jsonb);

insert into EncodingOfRandS
   select 'R' as Key, json_build_object('a', a)::jsonb as Value
   from   R
   union
   select 'S' as Key, json_build_object('a', a)::jsonb as Value
   from   S order by 1;

\qecho 'Relation EncodingOfRandS'
table EncodingOfRandS;

-- Map function
drop function if exists mapper;
CREATE OR REPLACE FUNCTION mapper(KeyIn text, ValueIn jsonb)
RETURNS TABLE(KeyOut jsonb, ValueOut text) AS
$$
    SELECT ValueIn::jsonb, KeyIn;
$$ LANGUAGE SQL;

-- Reduce function
drop function if exists reducer;
CREATE OR REPLACE FUNCTION reducer(KeyIn jsonb, ValuesIn text[])
RETURNS TABLE(KeyOut jsonb, ValueOut text[]) AS
$$
	SELECT KeyIn, ValuesIn WHERE array['R']<@ ValuesIn::TEXT[] and not(array['S']<@ ValuesIn::TEXT[])
$$ LANGUAGE SQL;

WITH
Map_Phase AS (
    SELECT m.KeyOut, m.ValueOut 
    FROM   encodingOfRandS, LATERAL(SELECT KeyOut, ValueOut FROM mapper(key, value)) m
),
--select * from map_phase
Group_Phase AS (
    SELECT KeyOut, array_agg(Valueout) as ValueOut
    FROM   Map_Phase
    GROUP  BY (KeyOut)
),
--select * from group_phase
Reduce_Phase AS (
    SELECT r.KeyOut, r.ValueOut
    FROM   Group_Phase gp, LATERAL(SELECT KeyOut, ValueOut FROM reducer(gp.KeyOut, gp.ValueOut)) r
)
SELECT KeyOut->'a' as a FROM Reduce_Phase;


\qecho ' '
\qecho 'Question 1.c'

drop table if exists R; 
drop table if exists S;

create table R(a int, b int); 
create table S(b int, c int);
--
insert into R values (1,2),(2,3),(3,4),(4,5);
insert into S values (2,12),(4,14),(5,15);

\qecho 'Relation R'
table R;

\qecho 'Relation S'
table S;

drop table if exists EncodingOfRandS;
create table EncodingOfRandS(key text, value jsonb);

insert into EncodingOfRandS
   select b as Key, json_build_object('R', 'R', 'a', a)::jsonb as Value
   from   R
   union
   select b as Key, json_build_object('S', 'S', 'c', c)::jsonb as Value
   from   S order by 1;

\qecho 'Relation EncodingOfRandS'
table EncodingOfRandS;

-- Map function
drop function if exists mapper;
CREATE OR REPLACE FUNCTION mapper(KeyIn text, ValueIn jsonb)
RETURNS TABLE(KeyOut text, ValueOut jsonb) AS
$$
    SELECT KeyIn, ValueIn;
$$ LANGUAGE SQL;

-- Reduce function
drop function if exists reducer;
CREATE OR REPLACE FUNCTION reducer(KeyIn text, ValuesIn jsonb[])
RETURNS TABLE(KeyOut jsonb, ValueOut text) AS
$$
	with temp as(	
    SELECT unnest(ValuesIn) as key,KeyIn as val where cardinality(valuesIn)>=2)
    select t.key->'a', t.val from temp t where exists(select * from temp where key->'S' is not null);
$$ LANGUAGE SQL;

with
-- mapper phase
Map_Phase AS (
    SELECT m.KeyOut, m.ValueOut 
    FROM   EncodingOfRandS r, LATERAL(SELECT q.KeyOut, q.ValueOut FROM mapper(r.key, r.value)q)m
),
/*
2	{"R": "R", "a": 1}
2	{"S": "S", "c": 12}
3	{"R": "R", "a": 2}
4	{"S": "S", "c": 14}
*/
--select * from Map_Phase;
-- group phase
Group_Phase AS (
    SELECT KeyOut, array_agg(Valueout) as ValueOut
    FROM   Map_Phase
    GROUP  BY (KeyOut)
),
--select * from group_phase;
/*
2	{{"R": "R", "a": 1},{"S": "S", "c": 12}}
4	{{"S": "S", "c": 14},{"R": "R", "a": 3}}
3	{{"R": "R", "a": 2}}
5	{{"S": "S", "c": 15},{"R": "R", "a": 4}}
*/
-- reducer phase
Reduce_Phase AS (
    SELECT r.KeyOut as a, r.ValueOut as b
    FROM   Group_Phase gp, LATERAL(SELECT KeyOut, ValueOut FROM reducer(gp.KeyOut, gp.ValueOut))r
    where r.KeyOut is not null 
)
SELECT * FROM Reduce_Phase;


\qecho ' '
\qecho 'Question 1.d'

drop table if exists R; 
drop table if exists S;
--drop table if exists T;

create table R(a int); 
create table S(a int);
create table T(a int);

insert into R values (1),(2),(3),(4);
insert into S values (2),(4),(5);
insert into T values (3),(4),(5),(6);

\qecho 'Relation R'
table R;

\qecho 'Relation S'
table S;

\qecho 'Relation T'
table T;

--drop table if exists EncodingOfRandSandT;
create table EncodingOfRandSandT(key text, value jsonb);

insert into EncodingOfRandSandT
   select 'R' as Key, json_build_object('a', a)::jsonb as Value
   from   R
   union
   select 'S' as Key, json_build_object('a', a)::jsonb as Value
   from   S 
   union
   select 'T' as Key, json_build_object('a', a)::jsonb as Value
   from  T order by 1;

\qecho 'Relation EncodingOfRandSandT'
table EncodingOfRandSandT;

-- Map function
drop function if exists mapper;
CREATE OR REPLACE FUNCTION mapper(KeyIn text, ValueIn jsonb)
RETURNS TABLE(KeyOut jsonb, ValueOut text) AS
$$
    SELECT ValueIn::jsonb, KeyIn;
$$ LANGUAGE SQL;

-- Reduce function
drop function if exists reducer;
CREATE OR REPLACE FUNCTION reducer(KeyIn jsonb, ValuesIn text[])
RETURNS TABLE(KeyOut jsonb, ValueOut text[]) AS
$$
	SELECT KeyIn, ValuesIn WHERE array['R']<@ ValuesIn::TEXT[] 
								and not(array['S']<@ ValuesIn::TEXT[] or array['T']<@ ValuesIn::TEXT[])
$$ LANGUAGE SQL;

WITH
Map_Phase AS (
    SELECT m.KeyOut, m.ValueOut 
    FROM   EncodingOfRandSandT, LATERAL(SELECT KeyOut, ValueOut FROM mapper(key, value)) m
),
--select * from map_phase
Group_Phase AS (
    SELECT KeyOut, array_agg(Valueout) as ValueOut
    FROM   Map_Phase
    GROUP  BY (KeyOut)
),
--select * from group_phase;
Reduce_Phase AS (
    SELECT r.KeyOut, r.ValueOut
    FROM   Group_Phase gp, LATERAL(SELECT KeyOut, ValueOut FROM reducer(gp.KeyOut, gp.ValueOut)) r
)
SELECT KeyOut->'a' as a FROM Reduce_Phase;

\qecho ' '
\qecho 'Q.2'
--2
drop table if exists R;
create table R(a int, b int); 
insert into R values (1,2),(2,3),(1,6),(2,4),(3,4),(4,5);

\qecho 'Relation R'
table R;

\qecho ' '
\qecho 'Output for Normal Query Given:'

SELECT r.A, array_agg(r.B), cardinality(array_agg(r.B))
FROM R r
GROUP BY (r.A)
HAVING COUNT(r.B) >= 2;

\qecho ' '
\qecho 'Output for Map-Reduce:'
drop function if exists mapper;
CREATE OR REPLACE FUNCTION mapper(A int,B int) 
RETURNS TABLE (B int, one int) AS
$$
 SELECT B, 1 as one;
$$ LANGUAGE SQL;

drop function if exists reducer;
CREATE OR REPLACE FUNCTION reducer(A int, ones int[]) 
RETURNS TABLE(A int, count int) AS
$$
   SELECT A, CARDINALITY(ones) as count;
$$ LANGUAGE SQL;

WITH 
-- mapper phase
     map_output AS (SELECT r.a,q.b,q.one
                    FROM   R r,
                            LATERAL(SELECT p.b, p.one
                                    FROM mapper(r.a,r.b) p) q),
-- group phase
    group_output AS (SELECT r.a,array_agg(r.b) as b_agg,array_agg(r.one) as ones
                     FROM   map_output r 
                     GROUP BY (r.a)),

-- reducer phase
   reduce_output as (SELECT r.a, q.b_agg, r.count 
                     FROM   group_output q,
                               LATERAL(SELECT p.a, p.count
                                       FROM reducer(q.a, q.ones) p) r 
                     where r.count>=2)
--output
SELECT r.a,r.b_agg as b, r.count
from reduce_output r;

\qecho ' '
\qecho 'Q.3'
--3

\qecho ' '
\qecho 'Question 3.a'

drop table if exists R;
drop table if exists S;

create table R(k text, v int);
create table S(k text, w int);

insert into R values ('a', 1),
                     ('a', 2),
                     ('b', 1),
                     ('c', 3);


insert into S values ('a', 1),
                     ('a', 3),
                     ('c', 2),
                     ('d', 1),
                     ('d', 4);
                    
\qecho 'Relation R'
table R;

\qecho 'Relation S'
table S;

CREATE TYPE rs AS (rv int[], sw int[]);
     

--drop view if exists cogroup; 
create or replace view cogroup as 
WITH  Kvalues AS (SELECT r.K FROM R r 
                  UNION 
                  SELECT s.K FROM S s),
      R_K AS (SELECT r.K, ARRAY_AGG(r.V) AS RV_values
              FROM   R r
              GROUP BY (r.K)
              UNION 
              SELECT k.K, '{}' AS RV_values 
              FROM   Kvalues k
              WHERE  k.K NOT IN (SELECT r.K FROM R r)),
      S_K AS (SELECT s.K, ARRAY_AGG(s.W) AS SW_values
              FROM   S s
              GROUP BY (K)
              UNION 
              SELECT k.K, '{}' AS SW_values 
              FROM   Kvalues k
              WHERE  k.K NOT IN (SELECT s.K FROM S s)) 
SELECT  K, (RV_values, SW_values)::rs as rs_values
FROM    R_K NATURAL JOIN S_K;

select K, rs_values from cogroup;

--select K,(Rs_values::rs).rv,(Rs_values::rs).sw from cogroup;

--select K, (RV_values, SW_values) from cogroup;
/*
a	("{1,2}","{1,3}")
b	({1},{})
c	({3},{2})
d	({},"{1,4}")*/

\qecho ' '
\qecho 'Question 3.b'

select K,unnest((Rs_values::rs).rv) as rv_values from cogroup
where (Rs_values::rs).sw !='{}' and (Rs_values::rs).rv !='{}' order by 1;

/*Alternatively,
select K,unnest(RV_values) from cogroup
where SW_values !='{}' and rv_values!='{}' order by 1;*/
/*
a	1
a	2
c	3*/

\qecho ' '
\qecho 'Question 3.c'

--normal query
\qecho 'Output for Normal Query Given:'
SELECT distinct r.K as rK, s.K as sK
FROM R r, S s
WHERE ARRAY(SELECT r1.V
FROM R r1
WHERE r1.K = r.K) <@ ARRAY(SELECT s1.W
FROM S s1
WHERE s1.K = s.K);


--using cogroup
\qecho 'Output using Co group:'
select distinct c1.K as rK, c2.K as sK
from cogroup c1, cogroup c2
where (c1.Rs_values::rs).rv <@ (c2.Rs_values::rs).sw
and (c1.Rs_values::rs).rv !='{}' and (c2.Rs_values::rs).sw !='{}'
--and c1.K <> c2.K 
order by 1;

/*
Alternatively,
select distinct c1.K as rK, c2.K as sK
from cogroup c1, cogroup c2
where c1.rv_values <@ c2.sw_values
and c1.rv_values!='{}' and c2.sw_values!='{}'
--and c1.K <> c2.K 
order by 1;
*/
/*
b	a
b	d
c	a*/

drop view cogroup;

\qecho ' '
\qecho 'Question 4'

drop table if exists R;
drop table if exists S;

create table R(k1 text, k2 text);
create table S(k1 text, k2 text);

insert into R values ('a', 'a'),
                     ('b', 'b'),
                     ('c', 'c'),
                     ('d', 'd'),
                     ('e', 'e');

insert into S values ('a', 'a'),
                     ('c', 'c'),
                     ('f', 'f');

\qecho 'Relation R'
table R;

\qecho 'Relation S'
table S;

CREATE TYPE rs_text AS (rv text[], sw text[]);

--drop view if exists cogroup; 
create or replace view cogroup as 
WITH  Kvalues AS (SELECT r.K1 FROM R r 
                  UNION 
                  SELECT s.K1 FROM S s),
      R_K AS (SELECT r.K1, ARRAY_AGG(r.k2) AS Rk_values
              FROM   R r
              GROUP BY (r.K1)
              UNION 
              SELECT k.K1, '{}' AS Rk_values 
              FROM   Kvalues k
              WHERE  k.K1 NOT IN (SELECT r.K1 FROM R r)),
      S_K AS (SELECT s.K1, ARRAY_AGG(s.k2) AS Sk_values
              FROM   S s
              GROUP BY (K1)
              UNION 
              SELECT k.K1, '{}' AS Sk_values 
              FROM   Kvalues k
              WHERE  k.K1 NOT IN (SELECT s.K1 FROM S s))              
SELECT  K1, (Rk_values, Sk_values)::rs_text as rs_values
FROM    R_K NATURAL JOIN S_K;
select K1, rs_values from cogroup;

--select K,(Rs_values::rs).rv,(Rs_values::rs).sw from cogroup;

--SELECT  K1, Rk_values, Sk_values
--FROM    R_K NATURAL JOIN S_K;
--select K1, (Rk_values, Sk_values) from cogroup;
/*
a	({a},{a})
b	({b},{})
c	({c},{c})
d	({d},{})
e	({e},{})
f	({},{f})
*/

\qecho ' '
\qecho 'Question 4.a'

select c1.k1 as K
from cogroup c1
where (c1.Rs_values::rs_text).rv = (c1.Rs_values::rs_text).sw
order by 1;

/*
Alternatively,
select c1.k1 as K
from cogroup c1
where c1.Rk_values = c1.Sk_values
order by 1;*/
/*
a
c
*/


\qecho ' '
\qecho 'Question 4.b'

--select K,(Rs_values::rs).rv,(Rs_values::rs).sw from cogroup;

select * from 
(select c1.k1 as K
from cogroup c1
where (c1.Rs_values::rs_text).sw='{}'
union
select c2.k1 as K
from cogroup c2
where (c2.Rs_values::rs_text).rv='{}') q
order by 1;


/*
Alternatively,
select * from 
(select c1.k1 as K
from cogroup c1
where c1.sk_values='{}'
union
select c2.k1 as K
from cogroup c2
where c2.rk_values='{}') q
order by 1;*/

/*
b
d
e
f
*/

drop view cogroup;

\qecho ' '
\qecho 'Part 2'

\qecho ' '
\qecho 'Question 5'

create table student(sid  text, sname  text,  major  text, byear int);
insert into student values('s100','Eric','CS',1987),
('s101','Nick','Math',1990),
('s102','Chris','Biology',1976),
('s103','Dinska','CS',1977),
('s104','Zanna','Math',2000);

\qecho 'Relation Student'
select * from student;

create table course(cno text, cname text, dept text);
insert into course values ('c200','PL','CS'),
('c201','Calculus','Math'),
('c202','Dbs','CS'),
('c301','AI','CS'),
('c302','Logic','Philosophy');

\qecho 'Relation course'
select * from course;

CREATE TABLE enroll (
	sid text,
	cno text,
	grade text
);

insert into enroll values 
     ('s100','c200', 'A'),
     ('s100','c201', 'B'),
     ('s100','c202', 'A'),
     ('s101','c200', 'B'),
     ('s101','c201', 'A'),
     ('s102','c200', 'B'),
     ('s103','c201', 'A'),
     ('s101','c202', 'A'),
     ('s101','c301', 'C'),
     ('s101','c302', 'A'),
     ('s102','c202', 'A'),
     ('s102','c301', 'B'),
     ('s102','c302', 'A'),
     ('s104','c201', 'D');
   
\qecho 'Relation enroll'
select * from enroll;
    
CREATE TABLE major (sid text, major text);
INSERT INTO major VALUES ('s100','French'),
('s100','Theater'),
('s100', 'CS'),
('s102', 'CS'),
('s103', 'CS'),
('s103', 'French'),
('s104',  'Dance'),
('s105',  'CS');

\qecho 'Relation major'
select * from major;


CREATE TYPE studentType AS (sid text);
CREATE TYPE courseType as (cno text);

CREATE TYPE gradeCoursesType AS (grade text, courses courseType[]);
CREATE TABLE studentGrades(sid text, gradeInfo gradeCoursesType[]);

CREATE TYPE gradeStudentsType AS (grade text, student studentType[]);
CREATE TABLE courseGrades(cno text, gradeInfo gradeStudentsType[]);


\qecho ' '
\qecho 'Question 5.a'

insert into courseGrades
with e as (select cno, grade, array_agg(row(sid)::studentType) as students
           from enroll
           group by (cno, grade)),
     f as (select cno, array_agg(row(grade, students)::gradeStudentsType) as gradeInfo
           from e
           group by (cno))
select * from f order by cno;

select * from courseGrades;

\qecho ' '
\qecho 'Question 5.b'
insert into studentGrades
with 
e as
	(select sid,grade,array_agg(row(cno)::coursetype) as courses 
	from coursegrades c, unnest(c.gradeinfo) g, unnest(g.student) s 
	group by (s.sid,g.grade)), 
f as
	(select sid,array_agg(row(grade,courses)::gradeCoursesType) as gradeinfo 
	from e 
	group by sid) 
select * from f;

select * from studentgrades;


\qecho ' '
\qecho 'Question 5.c'
CREATE TABLE jcourseGrades (courseInfo JSONB);

insert into jcourseGrades
with e as  (select cno, grade,
                   array_to_json(array_agg(json_build_object('sid',sid))) as students
            from   enroll
            group by(cno,grade) order by 1),

     f as   (select json_build_object('cno', cno, 'gradeInfo', 
       array_to_json(array_agg(json_build_object('grade', grade, 'students', students)))) as courseInfo
             from   e
             group by (cno))
select  courseInfo from f;

select * from jcoursegrades;

\qecho ' '
\qecho 'Question 5.d'

CREATE TABLE jStudentGrades (studentInfo JSONB);

insert into jstudentGrades
with e as
(SELECT s->'sid' as sid, g -> 'grade' as grade, array_to_json(array_agg(json_build_object('cno',cg.courseinfo -> 'cno'))) as courses
FROM   jcoursegrades cg, jsonb_array_elements(cg.courseinfo -> 'gradeInfo') g , jsonb_array_elements(g ->'students') s
group by sid,grade),
f as 
(select
json_build_object('sid',sid,'gradeinfo',array_to_json(array_agg(json_build_object('grade',grade,'courses',courses)))) as studentinfo
from e
group by sid)
select * from f;

select * from jstudentgrades;

\qecho ' '
\qecho 'Question 5.e'

WITH E AS 
(SELECT s.studentinfo->>'sid' as sid, c->>'cno' as cno
FROM jstudentGrades s, jsonb_array_elements(s.studentinfo->'gradeinfo') g, jsonb_array_elements(g->'courses') c),
F AS (SELECT sid, dept, array_to_json(array_agg(json_build_object('cno',cno, 'cname', cname))) as courses
FROM E NATURAL JOIN Course
GROUP BY(sid, dept)),
--select * from f
q as
(select sid,array_agg(json_build_object('dept',dept,'courses',courses)) as courseInfo from f group by sid)
select json_build_object('sid',s.sid,'sname',s.sname,'deptInfo',q.courseInfo) as student_data 
from q join student s on(s.sid=q.sid)
where s.sid in (SELECT sid
FROM major m
WHERE major = 'CS');

\qecho ' '
\qecho 'Part 3: Refer to the .pdf file'



--Older Version for Q5:

/*create type s_type as (sid text);
create type gs_type as (grade text, students text[]);

create table courseGrades(cno text, gradeInfo gs_type[]);

insert into courseGrades
with 
e as (select cno, grade, array_agg(row(sid)::s_type) as students
	  from enroll group by (cno, grade)),
f as (select cno, array_agg(row(grade, students)::gs_type) as gradeInfo
	  from e group by (cno))
select * from f order by cno;

select * from courseGrades;

--table courseGrades;*/

/*--select cg.cno as cno, g.grade as grade ,q as sid  from coursegrades cg, unnest(cg.gradeinfo) g, unnest(g.students) q;
create type c_type as (cno text);
create type gc_type as (grade text, courses text[]);

create table studentGrades(sid text, gradeInfo gc_type[]);
insert into studentGrades
with k as 
(select cg.cno as cno, g.grade as grade ,q as sid  from coursegrades cg, unnest(cg.gradeinfo) g, unnest(g.students) q),
e as (select sid, grade, array_agg(row(cno)::c_type) as courses
	  from k group by (sid, grade)),
f as (select sid, array_agg(row(grade, courses)::gc_type) as gradeInfo
	  from e group by (sid))
select * from f order by sid;

select * from studentgrades;

table studentgrades;

select regexp_replace(sid, '\(|\)', '','g'), gradeinfo from studentgrades s2;*/

/*CREATE TABLE jcourseGrades (courseInfo JSONB);

insert into jcourseGrades
with e as  (select cno, grade,
                   array_to_json(array_agg(json_build_object('sid',sid))) as students
            from   enroll
            group by(cno,grade) order by 1),

     f as   (select json_build_object('cno', cno, 'gradeInfo', 
       array_to_json(array_agg(json_build_object('grade', grade, 'students', students)))) as courseInfo
             from   e
             group by (cno))
select  courseInfo from f;

table jcourseGrades;*/
/*
{"cno": "c200", "gradeInfo": [{"grade": "B", "students": [{"sid": "s101"}, {"sid": "s102"}]}, {"grade": "A", "students": [{"sid": "s100"}]}]}
{"cno": "c201", "gradeInfo": [{"grade": "A", "students": [{"sid": "s101"}, {"sid": "s103"}]}, {"grade": "D", "students": [{"sid": "s104"}]}, {"grade": "B", "students": [{"sid": "s100"}]}]}
{"cno": "c202", "gradeInfo": [{"grade": "A", "students": [{"sid": "s100"}, {"sid": "s101"}, {"sid": "s102"}]}]}
{"cno": "c301", "gradeInfo": [{"grade": "B", "students": [{"sid": "s102"}]}, {"grade": "C", "students": [{"sid": "s101"}]}]}
{"cno": "c302", "gradeInfo": [{"grade": "A", "students": [{"sid": "s101"}, {"sid": "s102"}]}]}
*/

/*CREATE TABLE jStudentGrades (studentInfo JSONB);

insert into studentGrades
with k as 
(select cg.cno as cno, g.grade as grade ,q as sid  from coursegrades cg, unnest(cg.gradeinfo) g, unnest(g.students) q),
e as (select sid, grade, array_agg(row(cno)::c_type) as courses
	  from k group by (sid, grade)),
f as (select sid, array_agg(row(grade, courses)::gc_type) as gradeInfo
	  from e group by (sid))
select * from f order by sid;*/


/*
\qecho ' '
\qecho 'Question 6'

\qecho ' '
\qecho 'Question 6.a'
\qecho 'Refer to the .png file'

\qecho ' '
\qecho 'Question 6.b'
\qecho 'Refer to the .png file'

\qecho ' '
\qecho 'Question 7'

\qecho ' '
\qecho 'Question 7.a'
match (:student) - [r] -> () 
return type(r)


\qecho ' '
\qecho 'Question 7.b'

match(s:student{name:"John"}) - [:buys] -> (b:book)
where b.price>=50
return s

\qecho ' '
\qecho 'Question 7.c'

match(s:student) - [:buys] -> (:book) - [:cites] -> (b:book)
where b.price>=50
return s

\qecho ' '
\qecho 'Question 7.d'

MATCH(b1:Book) - [:cites*] -> (b2:Book)
WHERE b1.price>50
RETURN b2

Alternatively,

MATCH(b2:Book) - [:citedby*] -> (b1:Book)
WHERE b1.price>50
RETURN b2

\qecho ' '
\qecho 'Question 7.e'

match(b:book) <- [:buys] - (s:student) - [:majors] -> (m1:major),
(s) - [:majors] -> (m2:major)
where m1.major='CS' and m2.major='Math'
return b,count(s) 

Alternatively,

match(b:book) <- [:buys] - (s:student) - [:majors] -> (m:major)
where m.major='CS' and m.major='Math'
return b,count(s) 
*/

\c postgres;
drop database sp;