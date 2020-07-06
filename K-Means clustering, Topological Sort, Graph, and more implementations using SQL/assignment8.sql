CREATE DATABASE sp;
--Connecting database 
\c sp; 


\qecho ' '
\qecho 'Part 1 - Object Relational Programming'


\qecho ' '
\qecho 'Question 1'

CREATE TABLE Tree(parent int, child int);
INSERT INTO Tree VALUES (1,2), (1,3), (1,4), (2,5), (2,6), (3,7), (5,8), (7,9), (9,10);

TABLE Tree;

CREATE TABLE V(vertex int);
INSERT INTO V VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10);

select * from V;

create table a_anc(a int, b int, dist int);
create table b_anc(a int, b int, dist int);

CREATE OR REPLACE FUNCTION a_ancestors(m int)
RETURNS void AS
$$
declare 
par int := (select parent from tree where child=m);
dist int := 0;
begin
	truncate a_anc;
	insert into a_anc values(m, m, dist);
	while par is not null
	loop
		dist:= dist + 1;
		insert into a_anc values(par, m, dist);
		par := (select parent from tree where child=par);
	end loop;
end
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION b_ancestors(m int)
RETURNS void AS
$$
declare 
par int := (select parent from tree where child=m);
dist int := 0;
begin
	truncate b_anc;
	insert into b_anc values(m, m, dist);
	while par is not null
	loop
		dist:= dist + 1;
		insert into b_anc values(par, m, dist);
--		par := null;
		par := (select parent from tree where child=par);
	end loop;
end
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION distance(m int, n int) RETURNS int AS
$$
  DECLARE
  result int;
  begin
	perform a_ancestors(m);
	perform b_ancestors(n);
    result :=(select t1.dist+t2.dist from a_anc t1, b_anc t2 where t1.a=t2.a
				order by t1.dist,t2.dist limit 1);
	return result;
  END;
$$ LANGUAGE plpgsql;

SELECT v1.vertex AS v1, v2.vertex as v2, distance(v1.vertex, v2.vertex) as distance
FROM   V v1, V v2
WHERE  v1.vertex != v2.vertex ORDER BY 3,1,2;

drop table a_anc;
drop table b_anc;
drop function a_ancestors;
drop function b_ancestors;

/*
truncate a_anc;
truncate b_anc;
select a_ancestors(8);
select b_ancestors(4);
*/

/*
select t1.b as start,t1.a as lca, t2.b as end, 
t1.dist as start_to_anc, t2.dist as end_to_anc, 
t1.dist+t2.dist as distance from a_anc t1,b_anc t2 where t1.a=t2.a
order by t1.dist,t2.dist limit 1;

select q.v1, q.v2,q.distance from (
SELECT v1.vertex AS v1, v2.vertex as v2, distance(v1.vertex, v2.vertex) as distance
FROM   V v1, V v2 
WHERE  v1.vertex != v2.vertex ORDER BY 3,1,2 )q where q.v1=2 and q.v2=10
*/


\qecho ' '
\qecho 'Question 2'


CREATE TABLE Graph(source int, target int);
DELETE FROM Graph;

INSERT INTO Graph VALUES 
(      1 ,      2),
(      1 ,      3),
(      1 ,      4),
(      3 ,      4),
(      2 ,      5),
(      3 ,      5),
(      5 ,      4),
(      3 ,      6),
(      4 ,      6);

table graph;


CREATE OR REPLACE FUNCTION topologicalsort()
RETURNS table(index_ bigint, vertex_ int) as
$proc$
declare
node int;
begin
	drop table if exists visited;
	drop table if exists for_order;
	create table visited(vertex int, is_visited bool);
	insert into visited
	(select distinct(source),false from graph 
	union
	select distinct(target),false from graph);
	create table for_order(_order int[]);
	INSERT INTO for_order VALUES ('{}');
	CREATE OR REPLACE FUNCTION dfs(node int)
	RETURNS void AS
	$$
		DECLARE
		temp int[];
		curr int;
		begin
			update visited set is_visited=true where vertex=node;
			if(array[node] <@ (select _order from for_order))=false then
				temp=array_append(temp, node);
			end if;
			IF EXISTS (SELECT target FROM Graph WHERE source=node) THEN
				foreach curr in array(select array_agg(target) from graph where source=node group by source)
				loop
					if (select is_visited from visited where vertex=curr) = false then 
						perform dfs(curr);
					end if;
				end loop;
			end if;
			update for_order set _order=array_cat(temp,_order);
		END;
	$$ language plpgsql;

	foreach node in array(select array_agg(vertex) from visited)
	loop
		if (select is_visited from visited where vertex=node) = false then 
		perform dfs(node);
		end if;
	end loop;
	return query select row_number() over() as index_, q.a as vertex_ from (select unnest(_order) as a from for_order)q;
END;
$proc$ language plpgsql;


select * from topologicalsort();


\qecho ' '
\qecho 'Question 3'
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

select * from partsubpart;

CREATE TABLE IF NOT EXISTS basicPart(pid INTEGER, weight INTEGER);
DELETE FROM basicPart;

INSERT INTO basicPart VALUES
(   2,      5),
(   4,     50),
(   5,      3),
(   7,      6),
(   8,     10);

select * from basicpart;

create or replace function recursiveJoins()
returns table(pid int, sid int, quantity int)
as
$$
begin
return query (
select p1.pid,p2.sid,p1.quantity*p2.quantity as quantity from partsubpart p1, available_recursion p2 where p1.sid=p2.pid
except
select * from available_recursion
);
end;
$$ language 'plpgsql';


create or replace function AggregatedWeight(p int)
returns int as
$$
declare 
agg_weight int:=0;
begin
if (p in (select pid from basicpart))
	then return (select weight from basicpart where pid=p);
else
	drop table if exists available_recursion;
	CREATE table available_recursion(pid INTEGER, sid INTEGER, quantity INTEGER);
	insert into available_recursion(select * from partsubpart);
	
	while exists(select * from recursiveJoins())
	loop
		insert into available_recursion(select * from recursiveJoins());
	end loop;
	agg_weight= (select sum(a.quantity*b.weight) from available_recursion a, basicpart b where a.sid=b.pid 
	and a.pid=p and a.sid in(select pid from basicpart));
	return agg_weight;
end if;
end;
$$language 'plpgsql';


select distinct pid, AggregatedWeight(pid)
from   (select pid from partSubPart union select pid from basicPart) q order by 1;



\qecho ' '
\qecho 'Question 4'

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

table document;

create or replace function frequentSets(t int) 
returns table(frequentsets text[])
as
$$
begin
drop table if exists powerset;
create table powerset(subsets text[]);
with recursive pset as (
      select '{}'::text[] as S
      union
      select array(select * from UNNEST(S) union select x.y order by 1)
      from   pset S, (select distinct unnest(words) as y from document) x)
insert into powerset (select * from pset);

drop table if exists resultset;
create table resultset(frequentsets text[],docid text);
insert into resultset
(select p.subsets,d.doc from powerset p, document d 
where p.subsets <@ d.words);

return query (select r.frequentsets from resultset r group by r.frequentsets having count(r.docid)>= t);
end;
$$ language plpgsql;

\qecho 'frequentSets(1)'
select frequentSets(1);
\qecho ' '
\qecho 'frequentSets(2)'
select frequentSets(2);
\qecho ' '
\qecho 'frequentSets(3)'
select frequentSets(3);
\qecho ' '
\qecho 'frequentSets(4)'
select frequentSets(4);
\qecho ' '
\qecho 'frequentSets(5)'
select frequentSets(5);
\qecho ' '
\qecho 'frequentSets(6)'
select frequentSets(6);
\qecho ' '
\qecho 'frequentSets(7)'
select frequentSets(7);
\qecho ' '
\qecho 'frequentSets(8)'
select frequentSets(8);


\qecho ' '
\qecho 'Question 5'

-- Discussed this problem with some colleagues. 

CREATE TABLE Points (PId INTEGER, X FLOAT, Y FLOAT);

INSERT INTO Points VALUES
(   1 , 0 , 0),
(   2 , 2 , 0),
(   3 , 4 , 0),
(   4 , 6 , 0),
(   5 , 0 , 2),
(   6 , 2 , 2),
(   7 , 4 , 2),
(   8 , 6 , 2),
(   9 , 0 , 4),
(  10 , 2 , 4),
(  11 , 4 , 4),
(  12 , 6 , 4),
(  13 , 0 , 6),
(  14 , 2 , 6),
(  15 , 4 , 6),
(  16 , 6 , 6),
(  17 , 1 , 1),
(  18 , 5 , 1),
(  19 , 1 , 5),
(  20 , 5 , 5);

select * from points order by 1;

create or replace function set_labels(a float, b float) 
returns int
as
$$
begin
-- return closest centroid label for the given point x and y
return (select q.cid from (select cid,sqrt(power(a-x,2)+power(b-y,2)) as closest from centroid)q order by q.closest asc limit 1);
end;
$$ language plpgsql;


CREATE OR REPLACE FUNCTION kmeans(k int) RETURNS table(cid int, x float,y float) AS
$$
  DECLARE
  max_iter int:=1000;
  iter int:=0;
  begin
	drop table if exists centroid;
-- this table for assigning k clusters nearby x and y co-ordinates depending on avg of point labels
	create table centroid(cid int, x FLOAT, y FLOAT);
	insert into centroid (select p.pid as cid,p.x,p.y from Points p order by random() limit k);
	drop table if exists points_labels;
-- this table stores labels i.e. centroid id's for each point depending on the nearest centroid to that point
	create table points_labels(pid int, x FLOAT, y FLOAT, cid int);
	insert into points_labels (select p.pid, p.x, p.y, -1 from Points p);
	while iter!=max_iter -- until you reach max iterations defined
	loop
	--set the labels of each point depending on nearest centroid
		update points_labels as pl set cid=s.new_label
		from (select p.pid, set_labels(p.x::float, p.y::float) as new_label from points_labels p) s
		where pl.pid=s.pid;
	-- update the centroids by taking geometrics mean of points belonging to that centroid label	
		update centroid as c set x=s.x,y=s.y
		from (select pl.cid, avg(pl.x)::float as x, avg(pl.y)::float as y from points_labels pl, centroid c1 where c1.cid=pl.cid group by pl.cid) s
		where c.cid=s.cid;
	
		iter:=iter+1;
	end loop;
-- return 4 possible centroids with their co-ordinates 
  return query (select * from centroid);
  END;
$$ LANGUAGE plpgsql;

select * from kmeans(4);


\c postgres;
drop database sp;