-- In the problems related to simulating MapReduce in
-- Object-Relational PostgreSQL, we face the problem of "encoding"
-- relations (or multiple relations) into key-value stores.  In
-- addition, since a MapReduce program maps a key-value store to
-- another key-value store, we need to "decode" the output key-value
-- store to an relation of object-relation.  So the general method to
-- do is simulation is as followss:

--   1. Encode the relation (or relations) into a single key-value store
--   2. Run the MapReduce phase (map, group, reduce) on this key-value store
--   3. Decode the key-value store that is the result of this Mapreduce program
--      back to a relation (or relations).

-- There is a general strategy to transform a relation (or multiple
-- relations ) into a single key-value store. 

-- Consider the following relation R:

drop table r;

create table R (a int, b int, c int);
insert into R values (1,2,3), (4,5,6), (1,2,4);

table R;

-- a | b | c 
-----+---+---
-- 1 | 2 | 3
-- 4 | 5 | 6
-- 1 | 2 | 4
-- (3 rows)


-- Starting from this relation R, we can, using json objects, come up
-- with an encoding of R as a key-value store as follows:
-- Take for example the tuple (1,2,3) in R.
-- We will encode this tuple as the key-value pair 
--        ('R',{"a": 1, "b":2, "c": 1})
-- To do this, we will use the json_build_object PostgreSQL function:

drop table encodingofR;

create table encodingofR (key text, value jsonb);

insert into encodingofR select 'R' as Key, json_build_object('a', r.a, 'b', r.b, 'c', r.c)::jsonb as Value
                        from   R r;

table encodingofR;

-- This gives the following encoding for R. Each tuple of R is
-- represent using a json object with fields that correspond to the
-- attributes of that tuple in R.  Notice that this strategy works in
-- general for any relation, independent of the number of attributes
-- in that relations schema.

--  key |            value            
-----+-----------------------------
-- R   | {"a" : 1, "b" : 2, "c" : 3}   -- this key-value pair represents the R-tuple (1,2,3)
-- R   | {"a" : 4, "b" : 5, "c" : 6}   -- this key-value pair represents the R-tuple (4,5,6)
-- R   | {"a" : 1, "b" : 2, "c" : 4}   -- this key-value pair represents the R-tuple (1,2,4)
--(3 rows)


-- We can also then "decode" the encodingofR key-value store back to the relation R:

select r.value->'a' as a, r.value->'b' as b, r.value->'c' as c from encodingofR r;

-- a | b | c 
-----+---+---
-- 1 | 2 | 3
-- 4 | 5 | 6
-- 1 | 2 | 4
--(3 rows)


-- Another interesting aspect of this encoding strategy is that it is
-- possible to put multiple relations into the same key value store.

-- Let us add a binary relation S:

drop table S;

create table S (a int, d int);

insert into S values (1,2), (5,6), (2,1), (2,3);

drop table encodingofRandS;

create table encodingofRandS(key text, value jsonb);


insert into encodingofRandS select 'R' as Key, json_build_object('a', a, 'b', b, 'c', c)::jsonb as Value
                            from   R
                            union
                            select 'S' as Key, json_build_object('a', a, 'd', d)::jsonb as Value
                            from   S order by 1, 2;

table encodingofRandS;

-- key |          value           
-----+--------------------------
-- R   | {"a": 1, "b": 2, "c": 3}
-- R   | {"a": 1, "b": 2, "c": 4}
-- R   | {"a": 4, "b": 5, "c": 6}
-- S   | {"a": 1, "d": 2}
-- S   | {"a": 2, "d": 1}
-- S   | {"a": 2, "d": 3}
-- S   | {"a": 5, "d": 6}
--(7 rows)


-- Sample problem
-- Write, in PostgreSQL, a basic MapReduce program, i.e., a mapper
-- function and a reducer function, as well as a 3-phases simulation that
-- implements the set intersection of two unary relations $R(A$) and
-- $S(A)$, i.e., the relation $R intersect S$.  You can assume that the domain of
-- $A$ is integer.

-- EncodingOfRandS;

drop table R; drop table S;

create table R(a int); create table S(a int);

insert into R values (1),(2),(3),(4);
insert into S values (2),(4),(5);

drop table EncodingOfRandS;
create table EncodingOfRandS(key text, value jsonb);

insert into EncodingOfRandS
   select 'R' as Key, json_build_object('a', a)::jsonb as Value
   from   R
   union
   select 'S' as Key, json_build_object('a', a)::jsonb as Value
   from   S order by 1;

table EncodingOfRandS;

--  keyout  | valueout 
----------+----------
-- {"a": 1} | R
-- {"a": 2} | R
-- {"a": 3} | R
-- {"a": 4} | R
-- {"a": 2} | S
-- {"a": 4} | S
-- {"a": 5} | S
-- (7 rows)

-- Map function
CREATE OR REPLACE FUNCTION Map(KeyIn text, ValueIn jsonb)
RETURNS TABLE(KeyOut jsonb, ValueOut text) AS
$$
    SELECT ValueIn::jsonb, KeyIn;
$$ LANGUAGE SQL;

-- Reduce function
CREATE OR REPLACE FUNCTION Reduce(KeyIn jsonb, ValuesIn text[])
RETURNS TABLE(KeyOut text, ValueOut jsonb) AS
$$
    SELECT 'R intersect S'::text, KeyIn WHERE ARRAY['R','S']::text[] <@ ValuesIn::TEXT[];
$$ LANGUAGE SQL;

-- Simulate MapReduce Program and decode

WITH
Map_Phase AS (
    SELECT m.KeyOut, m.ValueOut 
    FROM   encodingOfRandS, LATERAL(SELECT KeyOut, ValueOut FROM Map(key, value)) m
),
Group_Phase AS (
    SELECT KeyOut, array_agg(Valueout) as ValueOut
    FROM   Map_Phase
    GROUP  BY (KeyOut)
),
Reduce_Phase AS (
    SELECT r.KeyOut, r.ValueOut
    FROM   Group_Phase gp, LATERAL(SELECT KeyOut, ValueOut FROM Reduce(gp.KeyOut, gp.ValueOut)) r
)
SELECT valueOut->'a' as A FROM Reduce_Phase order by 1;

-- a 
-- ---
-- 2
-- 4
--(2 rows)



-- Problem 1.a

-- Write, in PostgreSQL, a basic MapReduce program, i.e., a mapper
-- function and a reducer function, as well as a 3-phases simulation that
-- implements the projection $\pi_{A,B}(R)$ where $R(A, B,C)$ is a
-- relation. You can assume that the domains of $A$, $B$, $C$ are
-- integer.  (Recall that in a projection, duplicates are eliminated.)


-- Mapreduce of project_{A,B}(R) 

drop table R;

create table R (a int, b int, c int);

insert into R values (1,2,3), (4,5,6), (1,2,4);

table R;

-- a | b | c 
-----+---+---
-- 1 | 2 | 3
-- 4 | 5 | 6
-- 1 | 2 | 4
-- (3 rows)


create table EncodingOfR(key text, value jsonb);

insert into EncodingOfR select 'R' as Key, json_build_object('a', a, 'b', b, 'c', c)::jsonb as Value
                              from   R;
table EncodingOfR;

-- key |          value           
-------+--------------------------
-- R   | {"a": 1, "b": 2, "c": 3}
-- R   | {"a": 4, "b": 5, "c": 6}
-- R   | {"a": 1, "b": 2, "c": 4}
--(3 rows)


-- Map function
CREATE OR REPLACE FUNCTION Map(KeyIn text, ValueIn jsonb)
RETURNS TABLE(KeyOut jsonb, ValueOut jsonb) AS
$$
    SELECT ValueIn::jsonb - 'c', ValueIn::jsonb - 'c'; -- this removes the "c" field
$$ LANGUAGE SQL;

-- Reduce function
CREATE OR REPLACE FUNCTION Reduce(KeyIn jsonb, ValuesIn jsonb[])
RETURNS TABLE(KeyOut text, ValueOut jsonb) AS
$$
    SELECT 'project_{A,B}(R)'::text, KeyIn;
$$ LANGUAGE SQL;

-- Simulate MapReduce Program

WITH
Map_Phase AS (
    SELECT m.KeyOut, m.ValueOut 
    FROM   encodingOfR, LATERAL(SELECT KeyOut, ValueOut FROM Map(key, value)) m
),
Group_Phase AS (
    SELECT KeyOut, array_agg(Valueout) as ValueOut
    FROM   Map_Phase
    GROUP  BY (KeyOut)
),
Reduce_Phase AS (
    SELECT r.KeyOut, r.ValueOut
    FROM   Group_Phase gp, LATERAL(SELECT KeyOut, ValueOut FROM Reduce(gp.KeyOut, gp.ValueOut)) r
)
SELECT ValueOut->'a' as A, ValueOut->'b' AS B FROM Reduce_Phase order by 1,2;


-- a | b 
-----+---
-- 1 | 2
-- 4 | 5
--(2 rows)

-- Problem 1.b
-- Write, in PostgreSQL, a basic MapReduce program, i.e., a mapper
-- function and a reducer function, as well as a 3-phases simulation that
-- implements the set difference of two unary relations $R(A$) and
-- $S(A)$, i.e., the relation $R- S$.  You can assume that the domain of
-- $A$ is integer.

-- EncodingOfRandS;

drop table R; drop table S;

create table R(a int); create table S(a int);

insert into R values (1),(2),(3),(4);
insert into S values (2),(4), (5);

create table EncodingOfRandS(key text, value jsonb);

insert into EncodingOfRandS
   select 'R' as Key, json_build_object('a', a)::jsonb as Value
   from   R
   union
   select 'S' as Key, json_build_object('a', a)::jsonb as Value
   from   S order by 1;

table EncodingOfRandS;

--  keyout  | valueout 
----------+----------
-- {"a": 1} | R
-- {"a": 2} | R
-- {"a": 3} | R
-- {"a": 4} | R
-- {"a": 2} | S
-- {"a": 4} | S
-- {"a": 5} | S
-- (7 rows)

-- Map function
CREATE OR REPLACE FUNCTION Map(KeyIn text, ValueIn jsonb)
RETURNS TABLE(KeyOut jsonb, ValueOut text) AS
$$
    SELECT ValueIn::jsonb, KeyIn;
$$ LANGUAGE SQL;

-- Reduce function
CREATE OR REPLACE FUNCTION Reduce(KeyIn jsonb, ValuesIn text[])
RETURNS TABLE(KeyOut text, ValueOut jsonb) AS
$$
    SELECT 'R-S'::text, KeyIn WHERE ValuesIn <@ ('{R}'::TEXT[]) and 
                                    NOT ValuesIn <@ ('{S}'::TEXT[]);
$$ LANGUAGE SQL;

-- Simulate MapReduce Program and decode

WITH
Map_Phase AS (
    SELECT m.KeyOut, m.ValueOut 
    FROM   encodingOfRandS, LATERAL(SELECT KeyOut, ValueOut FROM Map(key, value)) m
),
Group_Phase AS (
    SELECT KeyOut, array_agg(Valueout) as ValueOut
    FROM   Map_Phase
    GROUP  BY (KeyOut)
),
Reduce_Phase AS (
    SELECT r.KeyOut, r.ValueOut
    FROM   Group_Phase gp, LATERAL(SELECT KeyOut, ValueOut FROM Reduce(gp.KeyOut, gp.ValueOut)) r
)
SELECT valueout->'a' as A FROM Reduce_Phase order by 1;

-- a 
-----
-- 1
-- 3
--(2 rows)




-- Problem 1.c

-- Write, in PostgreSQL, a basic MapReduce program, i.e., a mapper
-- function and a reducer function, as well as a 3-phases simulation
-- that implements the semijoin $R \ltimes S$ of two relations $R(A, B)$ and $S(B,C)$.
-- You can assume that the domains of $A$, $B$, and $C$ are integer.

/* Mapreduce for R join S */

-- Create Tables
DROP TABLE IF EXISTS R;
CREATE TABLE R(
    A INTEGER,
    B INTEGER
);

DROP TABLE IF EXISTS S;
CREATE TABLE S(
    B INTEGER,
    C INTEGER
);

-- Populate table
INSERT INTO R VALUES (1, 2), (2, 4), (3, 6), (4,6);
INSERT INTO S VALUES (4, 7), (5, 8), (6, 9), (4,10);

-- EncodingofRandS

drop table if exists EncodingOfRandS;

create table EncodingOfRandS(key text, value jsonb);

insert into EncodingOfRandS
   select 'R' as Key, json_build_object('a', a, 'b', b)::jsonb as Value
   from   R
   union
   select 'S' as Key, json_build_object('b', b, 'c', c)::jsonb as Value
   from   S order by 1;


table EncodingOfRandS;

-- key |       value       
-------+-------------------
-- R   | {"a": 3, "b": 6}
-- R   | {"a": 4, "b": 6}
-- R   | {"a": 1, "b": 2}
-- R   | {"a": 2, "b": 4}
-- S   | {"b": 4, "c": 10}
-- S   | {"b": 5, "c": 8}
-- S   | {"b": 4, "c": 7}
-- S   | {"b": 6, "CREATE OR REPLACE FUNCTION Reduce(KeyIn jsonb, ValuesIn jsonb[])
--(8 rows)

-- Map function
CREATE OR REPLACE FUNCTION Map(KeyIn text, ValueIn jsonb)
RETURNS TABLE(KeyOut jsonb, ValueOut jsonb) AS
$$
    SELECT CASE WHEN KeyIn = 'R' THEN ValueIn::jsonb - 'a' 
                ELSE ValueIn::jsonb - 'c' END,
           CASE WHEN KeyIn = 'R' THEN ValueIn::jsonb
                ELSE json_build_object('RelName', 'S')::jsonb END;
$$ LANGUAGE SQL;

-- Reduce function
CREATE OR REPLACE FUNCTION Reduce(KeyIn jsonb, ValuesIn jsonb[])
RETURNS TABLE(KeyOut text, ValueOut jsonb) AS
$$
    WITH    Rtuple AS (SELECT UNNEST(ValuesIn) as AB_pair
                       WHERE  ARRAY['{"RelName": "S"}']::jsonb[] <@ ValuesIn::jsonb[] AND
                              cardinality(ValuesIn) > 1)
    SELECT  'R semijoin S'::text, AB_pair::jsonb
    FROM    Rtuple
    WHERE   AB_pair::jsonb <> '{"RelName": "S"}'::jsonb;
$$ LANGUAGE SQL;

-- Simulate MapReduce Program

WITH
Map_Phase AS (
    SELECT m.KeyOut, m.ValueOut 
    FROM   encodingOfRandS, LATERAL(SELECT KeyOut, ValueOut FROM Map(key, value)) m
),
Group_Phase AS (
    SELECT KeyOut, array_agg(Valueout) as ValueOut
    FROM   Map_Phase
    GROUP  BY (KeyOut)
),
Reduce_Phase AS (
    SELECT r.KeyOut, r.ValueOut
    FROM   Group_Phase gp, LATERAL(SELECT KeyOut, ValueOut FROM Reduce(gp.KeyOut, gp.ValueOut)) r
)
SELECT ValueOut->'a' as A, ValueOut->'b' as B FROM Reduce_Phase order by 1,2;


-- a | b 
-----+---
-- 2 | 4
-- 3 | 6
-- 4 | 6
--(3 rows)


-- Problem 1.d
-- Let $R(A)$, $S(A)$, and $T(A)$ be unary relations that store integers.
-- Write, in PostgreSQL, a MapReduce program that implements the RA
-- expression $R - (S\cup T)$.  Also provide a simulation that evaluates
-- this program.

-- R - (S union T)
-- EncodingOfRandSandT;

drop table R; drop table S; drop table T;

create table R(a int); create table S(a int); create table T(a int);

insert into R values (1),(2),(3),(4), (9);
insert into S values (2),(4), (5);
insert into T values (3), (4), (7), (8);

drop table EncodingOfRandSandT;
create table EncodingOfRandSandT(key text, value jsonb);

insert into EncodingOfRandSandT
   select 'R' as Key, json_build_object('a', a)::jsonb as Value
   from   R
   union
   select 'S' as Key, json_build_object('a', a)::jsonb as Value
   from   S
   union
   select 'T' as Key, json_build_object('a', a)::jsonb as Value
   from   T order by 1;


select key, value from EncodingOfRandSandT order by 1,2;

-- key |  value   
-- -----+----------
-- R   | {"a": 1}
-- R   | {"a": 2}
-- R   | {"a": 3}
-- R   | {"a": 4}
-- R   | {"a": 9}
-- S   | {"a": 2}
-- S   | {"a": 4}
-- S   | {"a": 5}
-- T   | {"a": 3}
-- T   | {"a": 4}
-- T   | {"a": 7}
-- T   | {"a": 8}
--(12 rows)

-- Map function
CREATE OR REPLACE FUNCTION Map(KeyIn text, ValueIn jsonb)
RETURNS TABLE(KeyOut jsonb, ValueOut text) AS
$$
    SELECT ValueIn::jsonb, KeyIn;
$$ LANGUAGE SQL;

-- Reduce function
CREATE OR REPLACE FUNCTION Reduce(KeyIn jsonb, ValuesIn text[])
RETURNS TABLE(KeyOut text, ValueOut jsonb) AS
$$
    SELECT 'R-(S union T)'::text, KeyIn WHERE ValuesIn <@ ('{R}'::TEXT[]) and
                                              not (ValuesIn <@ ('{S}'::TEXT[])) and
                                              not (ValuesIn <@ ('{T}'::TEXT[]));
$$ LANGUAGE SQL;

-- Simulate MapReduce Program

WITH
Map_Phase AS (
    SELECT m.KeyOut, m.ValueOut 
    FROM   encodingOfRandSandT, LATERAL(SELECT KeyOut, ValueOut FROM Map(key, value)) m
),
Group_Phase AS (
    SELECT KeyOut, array_agg(Valueout) as ValueOut
    FROM   Map_Phase
    GROUP  BY (KeyOut)
),
Reduce_Phase AS (
    SELECT r.KeyOut, r.ValueOut
    FROM   Group_Phase gp, LATERAL(SELECT KeyOut, ValueOut FROM Reduce(gp.KeyOut, gp.ValueOut)) r
)
SELECT ValueOut->'a' as A FROM Reduce_Phase;

-- a 
-----
-- 1
-- 9
-- (2 rows)


-- Problem 2

-- Write, in PostgreSQL, a basic MapReduce program, i.e., a mapper
-- function and a reducer function, as well as a 3-phases simulation


-- SELECT r.A, array_agg(r.B), cardinality(array_agg(r.B))
-- FROM   R r
-- GROUP  BY (r.A)
-- HAVING COUNT(r.B) >= 2;

-- Here $R$ is a relation with schema $(A,B)$.  You can assume that
-- the domains of $A$ and $B$ are integers.

-- Encoding of R

drop table r;
create table R(a int, b int);

insert into R values (1,1), (1,2), (1,3), (2,1), (3,1), (3,2);

drop table EncodingOfR;
create table EncodingofR(key text, value jsonb);

insert into EncodingofR
  select 'R' as key, json_build_object('a', a, 'b', b) as value
  from   R;

select key, value from EncodingofR;


-- key |      value       
-- -----+------------------
-- R   | {"a": 1, "b": 1}
-- R   | {"a": 1, "b": 2}
-- R   | {"a": 1, "b": 3}
-- R   | {"a": 2, "b": 1}
-- R   | {"a": 3, "b": 1}
-- R   | {"a": 3, "b": 2}
-- (6 rows)

-- Map function
CREATE OR REPLACE FUNCTION Map(KeyIn text, ValueIn jsonb)
RETURNS TABLE(KeyOut jsonb, ValueOut jsonb) AS
$$
    SELECT ValueIn::jsonb - 'b', ValueIn::jsonb - 'a';    
$$ LANGUAGE SQL;

-- Reduce function
CREATE OR REPLACE FUNCTION Reduce(KeyIn jsonb, ValuesIn jsonb[])
RETURNS TABLE(KeyOut text, ValueOut jsonb) AS
$$
    SELECT 'result'::text, json_build_object('a', KeyIn -> 'a', 'bS', ValuesIn, 'numberOfBs', cardinality(ValuesIn))::jsonb
    WHERE  cardinality(ValuesIn) >= 2;
$$ LANGUAGE SQL;

-- Simulate MapReduce Program

WITH
Map_Phase AS (
    SELECT m.KeyOut, m.ValueOut 
    FROM   encodingOfR, LATERAL(SELECT KeyOut, ValueOut FROM Map(key, value)) m
),
Group_Phase AS (
    SELECT KeyOut, array_agg(Valueout) as ValueOut
    FROM   Map_Phase
    GROUP  BY (KeyOut)
),
Reduce_Phase AS (
    SELECT r.KeyOut, r.ValueOut
    FROM   Group_Phase gp, LATERAL(SELECT KeyOut, ValueOut FROM Reduce(gp.KeyOut, gp.ValueOut)) r
)
--SELECT KeyOut as key, ValueOut as value FROM Reduce_Phase;
-- SELECT ValueOut->'a' as A, UNNEST(ValueOut->'bS'::jsonb[])::text as Bs, ValueOut->'numberOfBs' as NumberOfBs FROM Reduce_Phase;

SELECT A, array_agg(B) as Bs, NumberOfBs
FROM 
(SELECT ValueOut->'a' as A, jsonb_array_elements(ValueOut->'bS')->'b' as B, ValueOut->'numberOfBs' as NumberOfBs FROM Reduce_Phase) q
 GROUP BY(A,NumberOfBs);

-- a |   bs    | numberofbs 
-----+---------+------------
-- 1 | {1,2,3} | 3
-- 3 | {1,2}   | 2
-- (2 rows)

--- Problem 3

-- $R(K,V)$ and $S(K,W)$ be two binary key-value pair relations.
-- Consider the cogroup transformation {\tt R.cogroup(S)} introduced
-- in the lecture on Spark.  You can assume that the domains of $K$,
-- $V$, and $W$ are integers.


-- Problem 3.a Define a PostgreSQL view that represent the co-group
-- transformation {\tt R.cogroup(S)}.  Show that this view works.

DROP TABLE R;
CREATE TABLE R (k INT, v INT);
INSERT INTO R VALUES (1, 0), (2, 2), (2, 3), (3, 5), (101, 10);

DROP TABLE S;
CREATE TABLE S (k INT, w INT);
INSERT INTO S VALUES (2, 4), (2, 5), (3, 1), (100, 101);

DROP TYPE VWs;
CREATE TYPE VWs AS (vs INT[], ws INT[]);

DROP CASCADE VIEW cogroup;
CREATE VIEW cogroup AS
    WITH Ks AS
         (SELECT k FROM R UNION SELECT k FROM S),
         Rk AS
         (SELECT k, ARRAY(SELECT r.v FROM R r WHERE r.k = ks.k) AS vs FROM Ks ks),
         Sk AS
         (SELECT k, ARRAY(SELECT s.w FROM S s WHERE s.k = ks.k) AS ws FROM Ks ks)
    SELECT k, (vs, ws)::VWs AS vws
    FROM Rk NATURAL JOIN Sk;

SELECT * FROM cogroup;

--  k  |        vws        
-----+-------------------
--   1 | ({0},{})
--   2 | ("{2,3}","{4,5}")
--   3 | ({5},{1})
-- 100 | ({},{101})
-- 101 | ({10},{})
-- (5 rows)

-- Problem 3.b Write a PostgreSQL query that use this {\tt cogroup}
-- view to compute $R{\ltimes} S$.

SELECT r.k, r.v FROM R r WHERE r.K IN (SELECT s.k
                                       FROM   S s);

-- k | v 
-- ---+---
-- 2 | 2
-- 2 | 3
-- 3 | 5
--(3 rows)



SELECT c.k, v
FROM   cogroup c, UNNEST((c.vws).vs) v
WHERE  EXISTS (SELECT 1
               FROM   UNNEST((c.vws).ws) q);

-- k | v 
-- ---+---
-- 2 | 2
-- 2 | 3
-- 3 | 5
-- (3 rows)

SELECT c.k, v
FROM   cogroup c, UNNEST((c.vws).vs) v
WHERE  (SELECT count(1)
        FROM   UNNEST((c.vws).ws) q) >= 1;

-- Problem 3.c Write a PostgreSQL query that uses this {\tt cogroup}
-- view to implement the SQL query

SELECT distinct r.K as rK, s.K as sK
FROM   R r, S s
WHERE  ARRAY(SELECT r1.V
             FROM   R r1
             WHERE  r1.K = r.K) <@ ARRAY(SELECT s1.W
                                         FROM   S s1
                                         WHERE  s1.K = s.K);


--  rk | sk 
-- ----+----
--  3 |  2
-- (1 row)


SELECT distinct r.K as rK, s.K as sK
FROM   cogroup r JOIN cogroup s ON ((r.vws).vs <@ ((s.vws).ws) and not(r.vws).vs = '{}');

-- rk | sk 
------+----
--  3 |  2
-- (1 row)

-- Problem 4
-- Let $A$ and $B$ be two unary relations of integers.  Consider the
-- {\tt cogroup} transformation introduced in the lecture on Spark.
-- Using an approach analogous to the one in Problem~\ref{cogroup}
-- solve the following problems:

-- Problem 4.a

-- Write a PostgreSQL query that uses the cogroup transformation to
--compute $A\cap B$.

DROP TABLE A;  DROP TABLE B;

CREATE TABLE A(x int);
CREATE TABLE B(x int);

INSERT INTO A VALUES (1),(2),(3),(4); INSERT INTO B VALUES (1),(3),(5);


DROP CASCADE VIEW cogroup;

CREATE OR REPLACE
 VIEW cogroup AS (SELECT row()::text as K, ARRAY(SELECT x FROM A)::int[] as As, ARRAY(select x FROM B)::int[] as Bs);

SELECT UNNEST(c.As) FROM cogroup c;

SELECT UNNEST(c.As) FROM cogroup c
INTERSECT
SELECT UNNEST(c.Bs) FROM cogroup c;

-- SELECT UNNEST(c.As) FROM cogroup c
-- INTERSECT
-- SELECT UNNEST(c.Bs) FROM cogroup c;


-- Problem 4.b
-- Write a PostgreSQL query that uses the cogroup operator
-- to compute the symmetric difference of $A$ and $B$, i.e., the expression
-- $$(A - B) \cup (B-A).$$

(SELECT UNNEST(c.As) FROM cogroup c
 EXCEPT
 SELECT UNNEST(c.Bs) FROM cogroup c)
UNION
(SELECT UNNEST(c.Bs) FROM cogroup c
 EXCEPT
 SELECT UNNEST(c.As) FROM cogroup c);


-- unnest 
----------
--      2
--      4
--      5
-- (3 rows)



-- Problem 5
CREATE TABLE student (sid TEXT, sname TEXT, major TEXT, byear INT);
INSERT INTO student VALUES
('s100', 'Eric'  , 'CS'     , 1988),
('s101', 'Nick'  , 'Math'   , 1991),
('s102', 'Chris' , 'Biology', 1977),
('s103', 'Dinska', 'CS'     , 1978),
('s104', 'Zanna' , 'Math'   , 2001),
('s105', 'Vince' , 'CS'     , 2001);

CREATE TABLE course (cno TEXT, cname TEXT, dept TEXT);
INSERT INTO course VALUES
('c200', 'PL'      , 'CS'),
('c201', 'Calculus', 'Math'),
('c202', 'Dbs'     , 'CS'),
('c301', 'AI'      , 'CS'),
('c302', 'Logic'   , 'Philosophy');
CREATE TABLE major (sid text, major text);
INSERT INTO major VALUES ('s100','French'),
('s100', 'Theater'),
('s100', 'CS'),
('s102', 'CS'),
('s103', 'CS'),
('s103', 'French'),
('s104', 'Dance'),
('s105', 'CS');

CREATE TABLE enroll (sid TEXT, cno TEXT, grade TEXT);
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

-- Problem 5.a


-- Write a PostgreSQL query that creates the nested relation {\tt
-- courseGrades}.  The type of this relation is \[{\tt (cno,
-- gradeInfo\{(grade, students \{(sid)\})\})}\] This relation stores
-- for each course, the grade information of the students enrolled in
-- this course.  In particular, for each course and for each grade,
-- this relation stores in a set the students who obtained that grade
-- in that course.

CREATE TYPE studentType AS (sid TEXT);
CREATE TYPE gradeStudentsType AS (grade TEXT, students studentType[]);
CREATE TABLE courseGrades (cno TEXT, gradeInfo gradeStudentsType[]);

INSERT INTO courseGrades
  WITH E AS
       (SELECT cno, grade, ARRAY_AGG(row(sid)::studentType) AS students
          FROM Enroll
         GROUP BY (cno, grade)),
       F AS
       (SELECT cno, ARRAY_AGG(row(grade, students)::gradeStudentsType) AS gradeInfo
          FROM E
         GROUP BY cno)
SELECT cno, gradeInfo FROM F;

SELECT * FROM courseGrades;

/*
 cno  |                             gradeinfo                             
------+-------------------------------------------------------------------
 c200 | {"(B,\"{(s101),(s102)}\")","(A,\"{(s100)}\")"}
 c302 | {"(A,\"{(s101),(s102)}\")"}
 c301 | {"(C,\"{(s101)}\")","(B,\"{(s102)}\")"}
 c202 | {"(A,\"{(s100),(s101),(s102)}\")"}
 c201 | {"(A,\"{(s101),(s103)}\")","(D,\"{(s104)}\")","(B,\"{(s100)}\")"}
(5 rows)
*/


-- Problem 5.b
-- Starting from this nested relation {\tt courseGrades}, write a
-- PostgreSQL that creates the nested relation {\tt studentGrades}
-- which is as described in the lecture.

CREATE TYPE courseType AS (cno TEXT);
CREATE TYPE gradeCoursesType AS (grade TEXT, courses courseType[]);
CREATE TABLE studentGrades (sid TEXT, gradeInfo gradeCoursesType[]);

INSERT INTO studentGrades
  WITH E AS
       (SELECT sid, grade, ARRAY_AGG(row(cno)::courseType) AS courses
          FROM courseGrades c,
               UNNEST(c.gradeInfo) g,
               UNNEST(g.students) s
         GROUP BY (sid, grade)),
       F AS
       (SELECT sid, ARRAY_AGG(row(grade, courses)::gradeCoursesType) AS gradeInfo
          FROM E
         GROUP BY sid)
SELECT sid, gradeInfo FROM F;

SELECT * FROM studentGrades;

/*
 sid  |                                gradeinfo                                 
------+--------------------------------------------------------------------------
 s100 | {"(A,\"{(c200),(c202)}\")","(B,\"{(c201)}\")"}
 s104 | {"(D,\"{(c201)}\")"}
 s102 | {"(A,\"{(c202),(c302)}\")","(B,\"{(c200),(c301)}\")"}
 s103 | {"(A,\"{(c201)}\")"}
 s101 | {"(A,\"{(c302),(c202),(c201)}\")","(B,\"{(c200)}\")","(C,\"{(c301)}\")"}
(5 rows)
*/

-- Problem 5.c

-- In the lecture, we defined the {\tt jstudentGrades} semi-structured
-- relation.  Write a PostgreSQL query that creates a {\tt
-- jcourseGrades} semi-structured relation which stores JSON objects
-- whose structure conforms with the structure of tuples as described
-- for the {\tt courseGrades} nested relation in
-- question~\ref{nestedrelation}.

CREATE TABLE jCourseGrades (courseInfo JSONB);

INSERT INTO jCourseGrades
  WITH E AS
       (SELECT cno, grade, ARRAY_TO_JSON(ARRAY_AGG(JSON_BUILD_OBJECT('sid', sid))) AS students
          FROM Enroll
         GROUP BY (cno, grade)),
       F AS
       (SELECT JSON_BUILD_OBJECT(
               'cno', cno,
               'gradeInfo', ARRAY_TO_JSON(ARRAY_AGG(JSON_BUILD_OBJECT('grade', grade,
                                                                      'students', students)))) as courseInfo
          FROM E
         GROUP BY cno)
SELECT * FROM F;

SELECT * FROM jCourseGrades;


/*
                                                                                          courseinfo                                                                                          
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 {"cno": "c200", "gradeInfo": [{"grade": "B", "students": [{"sid": "s101"}, {"sid": "s102"}]}, {"grade": "A", "students": [{"sid": "s100"}]}]}
 {"cno": "c302", "gradeInfo": [{"grade": "A", "students": [{"sid": "s101"}, {"sid": "s102"}]}]}
 {"cno": "c301", "gradeInfo": [{"grade": "C", "students": [{"sid": "s101"}]}, {"grade": "B", "students": [{"sid": "s102"}]}]}
 {"cno": "c202", "gradeInfo": [{"grade": "A", "students": [{"sid": "s100"}, {"sid": "s101"}, {"sid": "s102"}]}]}
 {"cno": "c201", "gradeInfo": [{"grade": "A", "students": [{"sid": "s101"}, {"sid": "s103"}]}, {"grade": "D", "students": [{"sid": "s104"}]}, {"grade": "B", "students": [{"sid": "s100"}]}]}
(5 rows
*/

--Problem 5.d

-- Repeat question~\ref{transform} but now for the semi-structured
-- relations {\tt jcourseGrades} and the {\tt jstudentGrades}.  In
-- other words, starting from this semi-structured relation {\tt
-- courseGrades}, write a PostgreSQL that creates the semi-structured
-- relation {\tt studentGrades}.


CREATE TABLE jStudentGrades (studentInfo JSONB);


INSERT INTO jStudentGrades
  WITH E AS
       (SELECT s -> 'sid' AS sid, g -> 'grade' AS grade,
               ARRAY_TO_JSON(ARRAY_AGG(JSON_BUILD_OBJECT('cno', cg.courseInfo -> 'cno'))) AS courses
          FROM jCourseGrades cg,
               JSONB_ARRAY_ELEMENTS(cg.courseInfo -> 'gradeInfo') g,
               JSONB_ARRAY_ELEMENTS(g -> 'students') s
         GROUP BY (sid, grade)),
       F AS
       (SELECT JSON_BUILD_OBJECT(
               'sid', sid,
               'gradeInfo', ARRAY_TO_JSON(ARRAY_AGG(JSON_BUILD_OBJECT('grade', grade,
                                                                      'courses', courses)))) as studentInfo
          FROM E
         GROUP BY sid)
SELECT * FROM F;

SELECT * FROM jStudentGrades;

/*
                                                                                               studentinfo                                                                                                 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 {"sid": "s100", "gradeInfo": [{"grade": "A", "courses": [{"cno": "c200"}, {"cno": "c202"}]}, {"grade": "B", "courses": [{"cno": "c201"}]}]}
 {"sid": "s104", "gradeInfo": [{"grade": "D", "courses": [{"cno": "c201"}]}]}
 {"sid": "s102", "gradeInfo": [{"grade": "A", "courses": [{"cno": "c202"}, {"cno": "c302"}]}, {"grade": "B", "courses": [{"cno": "c200"}, {"cno": "c301"}]}]}
 {"sid": "s103", "gradeInfo": [{"grade": "A", "courses": [{"cno": "c201"}]}]}
 {"sid": "s101", "gradeInfo": [{"grade": "A", "courses": [{"cno": "c302"}, {"cno": "c202"}, {"cno": "c201"}]}, {"grade": "B", "courses": [{"cno": "c200"}]}, {"grade": "C", "courses": [{"cno": "c301"}]}]}
(5 rows)
*/


--Problem 5.e

-- In the lecture on Nested and Semi-structured data models, we
-- considered the query ``For each student who major in `CS', list his
-- or her sid and sname, along with the courses she is enrolled in.
-- Furthermore, these courses should be grouped by the department in
-- which they are enrolled."  We formulated this query in the context
-- of nested relations.



WITH E AS (SELECT JSON_BUILD_OBJECT('sid', sg.studentInfo -> 'sid',
                                    'cno', c -> 'cno') AS studentCourse
             FROM jStudentGrades sg,
                  JSONB_ARRAY_ELEMENTS(sg.studentInfo -> 'gradeInfo') g,
                  JSONB_ARRAY_ELEMENTS(g -> 'courses') c),
     F AS (SELECT JSON_BUILD_OBJECT('sid', e.studentCourse ->> 'sid',
                                    'dept', c.dept,
                                    'courses', ARRAY_TO_JSON(ARRAY_AGG(JSON_BUILD_OBJECT('cno', c.cno, 'cname', c.cname))))
               AS studentCourses
             FROM E e, course c
            WHERE e.studentCourse ->> 'cno' = c.cno
            GROUP BY (e.studentCourse ->> 'sid', c.dept))
SELECT JSON_BUILD_OBJECT('sid', s.sid,
                         'sname', s.sname,
                         'courseInfo',
                         ARRAY_TO_JSON(ARRAY(
                                SELECT JSON_BUILD_OBJECT('dept', f.studentCourses ->> 'dept',
                                                         'courses', f.studentCourses ->> 'courses')
                                  FROM F f WHERE s.sid = f.studentCourses ->> 'sid')))
    AS studentInfo
  FROM student s
 WHERE s.sid IN (SELECT sid FROM major m WHERE major = 'CS');


/*
         studentinfo                                                                                                                                               
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 {"sid" : "s100", "sname" : "Eric", "courseInfo" : [{"dept" : "CS", "courses" : "[{\"cno\" : \"c200\", \"cname\" : \"PL\"},{\"cno\" : \"c202\", \"cname\" : \"Dbs\"}]"},{"dept" : "Math", "courses" : "[{\"cno\" : \"c201\", \"cname\" : \"Calculus\"}]"}]}
 {"sid" : "s102", "sname" : "Chris", "courseInfo" : [{"dept" : "CS", "courses" : "[{\"cno\" : \"c301\", \"cname\" : \"AI\"},{\"cno\" : \"c200\", \"cname\" : \"PL\"},{\"cno\" : \"c202\", \"cname\" : \"Dbs\"}]"},{"dept" : "Philosophy", "courses" : "[{\"cno\" : \"c302\", \"cname\" : \"Logic\"}]"}]}
 {"sid" : "s103", "sname" : "Dinska", "courseInfo" : [{"dept" : "Math", "courses" : "[{\"cno\" : \"c201\", \"cname\" : \"Calculus\"}]"}]}
 {"sid" : "s105", "sname" : "Vince", "courseInfo" : []}
(4 rows)
*/

DROP TABLE jStudentGrades;
DROP TABLE jCourseGrades;
DROP TABLE studentGrades;
DROP TABLE courseGrades;
DROP TYPE gradeCoursesType;
DROP TYPE gradeStudentsType;
DROP TYPE studentType;
DROP TYPE courseType;
DROP TABLE student;
DROP TABLE course;
DROP TABLE enroll;
DROP TABLE major;



