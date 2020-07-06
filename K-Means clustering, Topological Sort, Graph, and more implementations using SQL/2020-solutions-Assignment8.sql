-- Problem 1

-- Write a PostgreSQL function {\tt distance(m,n)} that computes the
-- distance in {\tt Tree} for any possible pair of different nodes $m$
-- and $n$ in {\tt Tree}.

DROP TABLE IF EXISTS Tree CASCADE;
CREATE TABLE Tree(parent int, child int);

INSERT INTO Tree VALUES (1,2), (1,3), (1,4), (2,5), (2,6), (3,7), (5,8), (7,9), (9,10);

-- The view V consists of all vertices in Tree
CREATE OR REPLACE VIEW V AS (SELECT parent as vertex
                             FROM   Tree
                             UNION  
                             SELECT child as vertex
                             FROM   Tree order by 1);

-- The relation Anc consist of all ancestor-descendant pair in Tree
DROP TABLE IF EXISTS Anc;
CREATE TABLE Anc(ancestor int, descendant int);

INSERT INTO Anc 
  WITH RECURSIVE AD(ancestor,descendant) AS (
    SELECT vertex, vertex FROM V
    UNION
    SELECT AD.ancestor, Tree.child
    FROM   AD JOIN Tree ON (AD.descendant = Tree.parent) )
  SELECT ancestor, descendant FROM AD order by ancestor, descendant;


-- The function LowestCommonAncestor(v1,v2) computes the lowest common ancestor
-- in the Tree of vertex v1 and v2
CREATE OR REPLACE FUNCTION LowestCommonAncestor(v1 int, v2 int)
RETURNS int AS
$$
WITH   CommonAncestorOf_v1_and_v2 AS (SELECT vertex as commonAnc
                                      FROM   V
                                      WHERE  vertex IN (SELECT ancestor
                                                        FROM   Anc
                                                        WHERE  descendant = v1
                                                        INTERSECT
                                                        SELECT ancestor
                                                        FROM   Anc
                                                        WHERE  descendant = v2))
SELECT a1.commonAnc
FROM   CommonAncestorOf_v1_and_v2 a1
WHERE  NOT EXISTS (SELECT 1
                   FROM   CommonAncestorOf_v1_and_v2 a2
                   WHERE  a1.commonAnc <> a2.commonAnc AND
                          (a1.commonAnc,a2.commonAnc) IN (SELECT ancestor, descendant
                                                          FROM   Anc));
$$ LANGUAGE SQL;

-- The function d(v1,v2) computes the distance between a node v1 and an ancestor v2
-- of v1 in Tree.   This distance equal the number of nodes on the path from
-- v1 to v2 in Tree minus 1.   This works since in Tree, each node has at most 1 parent.
CREATE OR REPLACE FUNCTION d(v1 int, v2 int) 
RETURNS bigint AS
$$
SELECT COUNT(1) -1
FROM (SELECT ancestor
      FROM   Anc
      WHERE  descendant = v1 and ancestor IN (SELECT descendant
                                              FROM   Anc
                                              WHERE  ancestor = v2)) v;
$$ LANGUAGE SQL;

-- The function distance(v1,v2) computes the distance between v1 and v2
-- by adding together the distance from v1 to the lowest common ancestor of
-- v1 and v2 and the distance from v2 to the lowest common ancestor of 
-- v1 and v2.

CREATE OR REPLACE FUNCTION distance(v1 int,v2 int) 
RETURNS bigint AS
$$
SELECT d(v1, lowestcommonancestor(v1,v2)) + d(v2,lowestcommonancestor(v1,v2));
$$ LANGUAGE SQL;

-- The following query computes the distance between all pairs of different
-- vertices in Tree

SELECT v1.vertex AS v1, v2.vertex as v2, distance(v1.vertex, v2.vertex) as distance
FROM   V v1, V v2 
WHERE  v1.vertex != v2.vertex ORDER BY 3,1,2;


-- Problem 2  Topological sort of a connected directed acyclic graph

create table remainingSubGraph(source integer, target integer);

create table remainingVertices(vertex integer);

create table ordering(index integer, vertex integer);


-- The function indegreeZeroVertex randomly select a vertex with
-- indegree 0 in the remain subgraph of Graph.
create or replace function indegreeZeroVertex() returns integer as
$$
   select vertex
   from   remainingVertices 
   where  not exists (select 1 
                      from   remainingSubGraph where target = vertex) order by random();
$$ language sql;

-- This function repeatedly choses a remaining vertex of indegree zero, places
-- this vertex as the next vertex in the ordering, and then removes from the
-- remaining subgraph those edges with source that vertex.
-- This procedures ends when there are no remaining vertices.

create or replace function topologicalSort() 
returns table(index integer, vertex integer) as
$$
declare index  integer;
        v integer;
begin
   delete from ordering;

   delete from remainingSubGraph;
   insert into remainingSubGraph select source, target from graph;

   delete from remainingVertices;
   insert into remainingVertices  (select source as vertex
                                   from   graph
                                   union  
                                   select target as vertex
                                   from   graph);
                

    index := 0;
    while exists (select 1 from remainingVertices)
    loop
      index := index+1;
      select * into v from indegreeZeroVertex();
      insert into ordering values(index, v);
      delete from remainingSubGraph where source = v;   
      delete from remainingVertices where remainingVertices.vertex = v;   
    end loop;
    
return query (select * from ordering order by 1);
end;
$$ language plpgsql;

-- Problem 3
-- Bill of materials problem
CREATE TABLE IF NOT EXISTS partSubPart(pid INTEGER, sid INTEGER, quantity INTEGER);
DELETE FROM partSubPart;

INSERT INTO partSubPart VALUES
(   1,   2,        4),
(   1,   3,        1),
(   3,   4,        1),
(   3,   5,        2),
(   3,   6,        3),
(   6,   7,        2),
(   6,   8,        3);


CREATE TABLE IF NOT EXISTS basicPart(pid INTEGER, weight INTEGER);
DELETE FROM basicPart;

INSERT INTO basicPart VALUES
(   2,      5),
(   4,     50),
(   5,      3),
(   7,      6),
(   8,     10);

select * from partsubpart;


select * from basicpart;



-- The solution is based on the following rules: 
-- ps_triples(p,s,q) :- partsubpart(p,s,q)                                                                         
-- ps_triples(p,s,q*q1) :- anc(p,s1,q1), partsubpart(s1,s,q)                                                       

-- The ps_triples relation contains each triple (p,s,q) where "p" is a
-- part, "s" is a direct or indirect subpart of "p" and "q" is
-- quantity with which "s" occurs as as subpart of "p".

-- We can then compute the weight of each part "p"
-- by computing the sum of the quantities of
-- the basics part of "p" multiplied by their respective weight

WITH RECURSIVE ps_triples(pid,sid,quantity) AS (
    SELECT pid, sid, quantity FROM partSubPart
    UNION
    SELECT ps1.pid, ps2.sid, ps1.quantity*ps2.quantity
    FROM   ps_triples ps1 JOIN partSubPart ps2 ON (ps1.sid = ps2.pid))
SELECT ps.pid, SUM(ps.quantity*bp.weight) as aggregatedweight
FROM   ps_triples ps JOIN basicPart bp ON (ps.sid=bp.pid)
GROUP  BY(ps.pid)
UNION 
SELECT pid, weight
FROM   basicPart order by 1;


/*    
 pid | aggregatedweight 
-----+------------------
   1 |              202
   2 |                5
   3 |              182
   4 |               50
   5 |                3
   6 |               42
   7 |                6
   8 |               10
(8 rows)
*/


-- We can turn these ideas into a function AggregatedWeight(p)
-- which computes the aggregated weight of part "p"

CREATE OR REPLACE FUNCTION AggregatedWeight(part int)
RETURNS bigint AS
$$
WITH RECURSIVE subPart(sid,quantity) AS (
    SELECT sid, quantity FROM partSubPart WHERE pid = part
    UNION
    SELECT ps.sid, s.quantity*ps.quantity
    FROM   subPart s JOIN partSubPart ps ON (s.sid = ps.pid))
SELECT weight
FROM   (SELECT SUM(quantity*weight) as weight
        FROM   subPart JOIN basicPart ON (sid=pid)) q
WHERE  part NOT IN (SELECT pid FROM basicPart)
UNION 
SELECT weight
FROM   basicPart 
WHERE  pid = part;
$$ LANGUAGE SQL;

-- The following query computes the aggregated weight of each part
select distinct pid, AggregatedWeight(pid)
from   (select pid from partSubPart union select pid from basicPart) q order by 1;

/*
 pid | aggregatedweight 
-----+------------------
   1 |              202
   2 |                5
   3 |              182
   4 |               50
   5 |                3
   6 |               42
   7 |                6
   8 |               10
(8 rows)
*/

-- The following is a iterative solution for the same problem

create table if not exists ps_triples(pid int, sid int, quantity int);
delete from ps_triples;


create or replace function new_ps_triples()
returns table (pid integer, sid integer, quantity integer) as
$$
  select  t.pid, ps.sid, t.quantity*ps.quantity
  from    ps_triples t, partSubpart ps
  where   t.sid = ps.pid
  except
  select  * from ps_triples;
$$ language sql;


-- the function ps_triples computes for                                                                            
-- each part each of its basic subpart along                                                                       
-- with the number of times that that subpart                                                                      
-- occurs                                                                                                          

create or replace function ps_triples()
returns table (pid integer, sid integer, quantity integer) as
$$
begin
   drop table ps_triples;
   create table ps_triples(pid integer, sid integer, quantity integer);

   insert into ps_triples select * from partSubPart;

   while exists( select * from new_ps_triples())
   loop
     insert into ps_triples select * from new_ps_triples();
   end loop;

   return query (select * from ps_triples ps
                 where  ps.sid in (select p.pid from basicPart p) order by 1,2);
end;
$$ language plpgsql;

-- the function aggregatedWeight returns for each part (including basic parts),                                     
-- the aggregated cost of that part                                                                                

create or replace function aggregatedWeight(p integer) returns bigint as
$$
   select  sum(q.quantity*bp.weight)
   from    (select * from ps_triples() part where part.pid=p) q, basicPart bp
   where   q.sid = bp.pid
   group   by (q.pid)
   union
   select weight
   from   basicpart
   where  pid=p;
$$ language sql;


-- Problem 4
-- Frequent Itemset Problem

create table if not exists document (doc text,  words text[]);
delete from document;

insert into document values 
('d7', '{C,B,A}'),
('d1', '{A,B,C}'),
('d8', '{B,A}'),
('d4', '{B,B,A,D}'),
('d2', '{B,C,D}'),
('d6', '{A,D,G}'),
('d3', '{A,E}'),
('d5', '{E,F}');

create table if not exists word(w text);
delete from word;

-- The relation "word" contains all the words that occur in the documents of the
-- input.   The frequent itemsets will be some of the subsets of the relation "word".
insert into word
 select distinct unnest(d.words)
 from   document d order by 1;

-- The relation "Candidates" will contain 
drop table if exists Candidates;
create table Candidates(C text[]);

-- The relation "FrequentSets" will at any time contains subsets of "word"
-- that are frequent according to a certain threshold "t".  Initially this
-- set will be empty and at the end it will contain all of the frequent sets.
drop table if exists FrequentSets;
create table FrequentSets(F text[]);
insert into FrequentSets values ('{}');

-- The function addWord adds a word "w" to a set of words "S".
create or replace function addWord(S text[], w text) returns text[] as
$$
   select array( select UNNEST(S) union select w order by 1);
$$ language sql;

-- The function removeWord removes a word "w" from a set of words "S".
create or replace function removeWord(S text[], w text) returns text[] as
$$
   select array( select UNNEST(S) except select w order by 1);
$$ language sql;

-- This function determines if X is frequent by counting the 
-- the number of documents whose words contain X.
-- If this number is at least "t" than X is frequent.
create or replace function isFrequent(X text[], t integer)
returns boolean as
$$
   select (select count(1)
           from   document d
           where  X <@ d.words) >= t;
$$ language sql;

-- This is the apriori pruning rule
-- Given a itemset C, we consider each set of the form C - {w} where
-- w is in C.   I.e., we consider each strict subset of C with one
-- less element than C.   If one of these subsets in not frequent then
-- we can deduce that C can not be frequent either.  On the other end,
-- if each of these subset is frequent then we need to proceed with C
-- and determine whether or not it is frequent.

create or replace function isCandidate(C text[]) returns boolean as
$$
select not exists(select  1
                  from    UNNEST(C) w
                  where   removeWord(C,w)::text[] not in (select F::text[] from currentLevelFrequentSets));
$$ language sql;

-- This function produces new Candidates by considering each discovered
-- frequent set "F" at the prior level and adding to it each word in "word" that
-- is not already in F.

create or replace function new_Candidates()
returns table (C text[]) AS
$$
  select   distinct addWord(F::text[],w)::text[]
  from     currentLevelFrequentSets F, word
  where    not(array[w]::text[] <@ F::text[])  -- this checks if "w" is not already in F
           and isCandidate(addWord(F::text[], w)::text[]);
$$ language sql;



create or replace function FrequentSets(t integer)
returns table(frequentSet text[]) as
$$
begin
--   drop table if exists Candidates;
--   create table Candidates(C text[]);

   drop table if exists Frequentsets;
   create table Frequentsets(F text[]);

   -- add the emptyset to frequentSets since it is frequent for any threshold "t"
  
   insert into FrequentSets select array[]::text[];

   drop table if exists nextLevelFrequentSets;
   create table  nextLevelFrequentSets(F text[]);

  --  add the emptyset to nextLevelFrequentSets since it is frequent for any threshold "t"

   insert into nextLevelFrequentSets select array[]::text[];

   drop table if exists currentLevelFrequentSets;
   create table  currentLevelFrequentSets(F text[]);   

   insert into currentLevelFrequentSets select * from nextLevelFrequentSets;


   while exists(select 1 from new_Candidates())
   loop
        -- We store in "currentLevelFrequentSets
        -- the current frequent sets on the level determined by the loop
        --- "currentLevelFrequentSets" is used in new_Candidates() and
                                                   -- is_Candidate()
        delete from currentLevelFrequentSets;
        insert into currentLevelFrequentSets select * from nextLevelFrequentSets;

        delete from nextLevelFrequentSets;
        insert into nextLevelFrequentSets select C from new_Candidates()
                                             where  isfrequent(C,t); -- and C not in (select * from frequentsets);

        insert into FrequentSets select * from nextLevelFrequentSets;
   end loop;

   return query (select * from FrequentSets);

end;
$$ language plpgsql;

select frequentSets(1);

/*
 frequentsets 
--------------
 {}
 {E}
 {G}
 {C}
 {A}
 {F}
 {B}
 {D}
 {A,E}
 {A,C}
 {C,D}
 {E,F}
 {B,C}
 {D,G}
 {A,B}
 {A,D}
 {A,G}
 {B,D}
 {A,D,G}
 {A,B,D}
 {B,C,D}
 {A,B,C}
(22 rows)
*/

select frequentsets(2);

/*
 frequentsets 
--------------
 {}
 {E}
 {C}
 {A}
 {B}
 {D}
 {A,C}
 {B,C}
 {A,B}
 {A,D}
 {B,D}
 {A,B,C}
(12 rows)
*/

select frequentsets(3);

/*
 frequentsets 
--------------
 {}
 {C}
 {A}
 {B}
 {D}
 {B,C}
 {A,B}
(7 rows)
*/


select frequentsets(4);

/*
 frequentsets 
--------------
 {}
 {A}
 {B}
 {A,B}
(4 rows)
*/

select frequentsets(5);

/*
 frequentsets 
--------------
 {}
 {A}
 {B}
(3 rows)
*/

select frequentsets(6);

/*
 frequentsets 
--------------
 {}
 {A}
(2 rows)
*/

select frequentsets(7);

/*
 frequentsets 
--------------
 {}
(1 row)
*/


-- Problem 5
-- K-means clustering

DROP TABLE IF EXISTS Points;
CREATE TABLE Points(
    PId INTEGER NOT NULL,
    x FLOAT,
    y FLOAT,
    PRIMARY KEY(PId)
);

-- Populate Table                                                                                                  
CREATE OR REPLACE FUNCTION populate_points(n INTEGER)
RETURNS VOID AS
$$
BEGIN
    FOR i IN 1..n LOOP
        INSERT INTO Points(PId, x, y)
        VALUES (i, RANDOM() * 100, RANDOM() * 100);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT populate_points(100);

CREATE OR REPLACE FUNCTION kmeans(k INTEGER)
RETURNS TABLE(PId INTEGER, x FLOAT, y FLOAT, Partition INTEGER) AS
$$
BEGIN
    -- Set up temporary tables                                                                                     
    DROP TABLE IF EXISTS kmeans_centroids;
    DROP TABLE IF EXISTS kmeans_results;
    CREATE TEMP TABLE kmeans_centroids(n SERIAL, x FLOAT, y FLOAT);
    CREATE TEMP TABLE kmeans_results(PId INTEGER, x FLOAT, y FLOAT, Partition INTEGER);

    INSERT INTO kmeans_results(PId, x, y)
    SELECT p.PId, p.x, p.y
    FROM Points p;

    -- Initial centroids                                                                                           
    INSERT INTO kmeans_centroids(x, y)
    SELECT p.x, p.y
    FROM Points p
    ORDER BY RANDOM()
    LIMIT k;

    -- Start clustering                                                                                            
    LOOP
        WITH
        distance_to_each_centroids AS (
            SELECT r.PId, c.n, ((c.x - r.x) ^ 2 + (c.y - r.y) ^ 2) AS distance
            FROM kmeans_results r, kmeans_centroids c
        ),
        shortest_distance_to_centroids AS (
            SELECT d.PId, MIN(d.distance) AS shortest_distance
            FROM distance_to_each_centroids d
            GROUP BY d.PId
        ),
        closest_centroids AS (
            SELECT r.PId, d.n
            FROM kmeans_results r
            JOIN shortest_distance_to_centroids sd
            ON sd.PId = r.PId
            JOIN distance_to_each_centroids d
            ON d.PId = r.PId AND d.distance = sd.shortest_distance
        )
        UPDATE kmeans_results r
        SET (Partition) = (
            SELECT cc.n
            FROM closest_centroids cc
            WHERE r.PId = cc.PId
        );

        -- If convergence then exit loop                                                                           
        IF NOT EXISTS (
            WITH
            new_centroids AS (
                SELECT r.Partition AS n, AVG(r.x) AS x, AVG(r.y) AS y
                FROM kmeans_results r
                GROUP BY r.Partition
            )
            SELECT c.x, c.y
            FROM kmeans_centroids c, new_centroids nc
            WHERE (c.x <> nc.x OR c.y <> nc.y)
            AND c.n = nc.n
            )
            THEN
            EXIT;
        END IF;

        -- Update centroids                                                                                        
        WITH
        new_centroids AS (
            SELECT r.Partition AS n, AVG(r.x) AS x, AVG(r.y) AS y
            FROM kmeans_results r
            GROUP BY r.Partition
        )
        UPDATE kmeans_centroids c
        SET (x, y) = (
            SELECT nc.x, nc.y
            FROM new_centroids nc
            WHERE c.n = nc.n
        );
    END LOOP;

    RETURN QUERY
    SELECT r.PId, r.x, r.y, r.Partition
    FROM kmeans_results r;
END;
$$ LANGUAGE plpgsql;

-- Test Function                                                                                                   
SELECT k.PId, k.x, k.y, k.Partition
FROM kmeans(10) k
ORDER BY k.PId;

SELECT k.Partition, COUNT(k.PId) AS n_of_points
FROM kmeans(10) k
GROUP BY k.Partition
ORDER BY k.Partition;


