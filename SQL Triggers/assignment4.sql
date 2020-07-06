CREATE DATABASE sp;
--Connecting database 
\c sp; 

\qecho 'Creating Tables'

CREATE TABLE student (
	sid int PRIMARY KEY,
	sname text,
	major text
);

CREATE TABLE course (
	cno int PRIMARY KEY,
	cname text,
	total int,
	max int
);

CREATE TABLE prerequisite (
	cno int references course(cno),
	prereq int references course(cno)
);

CREATE TABLE hastaken (
	sid int references student(sid),
	cno int references course(cno)
);

CREATE TABLE enroll (
	sid int references student(sid),
	cno int references course(cno)
);

CREATE TABLE waitlist (
	sid int references student(sid),
	cno int references course(cno),
	position int
);


\qecho 'Question 1 a'

\qecho 'Defining triggers for primary key in student table'

CREATE OR REPLACE FUNCTION check_Student_Id_constraint() RETURNS trigger AS
$$
BEGIN
 IF NEW.sid IN (SELECT sid FROM Student) THEN
    RAISE EXCEPTION 'sid already exist';
 END IF;
 RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';


CREATE TRIGGER check_Student_Id_constraint_trigger
BEFORE INSERT
ON Student 
FOR EACH ROW
EXECUTE PROCEDURE check_Student_Id_constraint();


\qecho 'Inserting new entry'
insert into student values(1,'Sanket','DS');

select * from student;

\qecho 'Inserting duplicate entry'
insert into student values(1,'Sanket','DS');

select * from student;


\qecho 'Defining trigger for primary key in course table'

CREATE OR REPLACE FUNCTION check_Course_No_constraint() RETURNS trigger AS
$$
BEGIN
 IF NEW.cno IN (SELECT cno FROM course) THEN
    RAISE EXCEPTION 'cno already exist';
 END IF;
 RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';


CREATE TRIGGER check_Course_No_constraint_trigger
BEFORE INSERT
ON Course 
FOR EACH ROW
EXECUTE PROCEDURE check_Course_No_constraint();

\qecho 'Inserting new entry'
insert into course values(1,'ADC',50,60);

select * from course;

\qecho 'Inserting duplicate entry'
insert into course values(1,'ML',40,50),(2,'ML',40,50);

select * from course;


\qecho ''
\qecho 'Question 1 b'
\qecho ''


\qecho 'Defining insert trigger on prerequisite table for foreign key constraint'
\qecho ''
CREATE OR REPLACE FUNCTION check_foreign_key_constraint_for_prerequisite() RETURNS trigger AS
$$
BEGIN
 IF NEW.cno not IN (SELECT cno FROM course) or new.prereq not in (select cno from course) THEN
    RAISE EXCEPTION 'Foreign Key constraint violation, value not present in primary key relation';
 END IF;
 RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';


CREATE TRIGGER check_foreign_key_constraint_for_prerequisite_trigger
BEFORE INSERT
ON prerequisite 
FOR EACH ROW
EXECUTE PROCEDURE check_foreign_key_constraint_for_prerequisite();

\qecho ''
\qecho 'Inserting into prerequisite table to check foreign constraint'
insert into prerequisite values(2,2);

\qecho ''
\qecho 'Defining insert trigger on hastaken table for foreign key constraint'
\qecho ''

CREATE OR REPLACE FUNCTION check_foreign_key_constraint_for_hastaken() RETURNS trigger AS
$$
BEGIN
 IF NEW.cno not IN (SELECT cno FROM course) or new.sid not in (select sid from student) THEN
    RAISE EXCEPTION 'Foreign Key constraint violation, value not present in primary key relation';
 END IF;
 RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER check_foreign_key_constraint_for_hastaken_trigger
BEFORE INSERT
ON hastaken 
FOR EACH ROW
EXECUTE PROCEDURE check_foreign_key_constraint_for_hastaken();

\qecho ''
\qecho 'Inserting into hastaken table to check foreign constraint'
insert into hastaken values(2,1);

\qecho ''
\qecho 'Defining insert trigger on enroll table for foreign key constraint'
\qecho ''

CREATE OR REPLACE FUNCTION check_foreign_key_constraint_for_enroll() RETURNS trigger AS
$$
BEGIN
 IF NEW.cno not IN (SELECT cno FROM course) or new.sid not in (select sid from student) THEN
    RAISE EXCEPTION 'Foreign Key constraint violation, value not present in primary key relation';
 END IF;
 RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER check_foreign_key_constraint_for_enroll_trigger
BEFORE INSERT
ON enroll 
FOR EACH ROW
EXECUTE PROCEDURE check_foreign_key_constraint_for_enroll();

\qecho ''
\qecho 'Inserting into enroll table to check foreign constraint'
insert into enroll values(2,2);

\qecho ''
\qecho 'Defining insert trigger on waitlist table for foreign key constraint'
\qecho ''

CREATE OR REPLACE FUNCTION check_foreign_key_constraint_for_waitlist() RETURNS trigger AS
$$
BEGIN
 IF NEW.cno not IN (SELECT cno FROM course) or new.sid not in (select sid from student) THEN
    RAISE EXCEPTION 'Foreign Key constraint violation, value not present in primary key relation';
 END IF;
 RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER check_foreign_key_constraint_for_waitlist_trigger
BEFORE INSERT
ON waitlist 
FOR EACH ROW
EXECUTE PROCEDURE check_foreign_key_constraint_for_waitlist();

\qecho ''
\qecho 'Inserting into waitlist table to check foreign constraint'
insert into waitlist values(2,2,1);

\qecho ''
\qecho 'Defining delete trigger on student table for cascade delete'
\qecho ''
CREATE OR REPLACE FUNCTION cascade_delete_on_student() RETURNS trigger AS
$$
BEGIN
 delete from enroll where sid=old.sid;
 delete from waitlist where sid=old.sid;
 RETURN old;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER cascade_delete_on_student_trigger
BEFORE DELETE
ON student 
FOR EACH ROW
EXECUTE PROCEDURE cascade_delete_on_student();


insert into enroll values(1,1);
select * from enroll;

insert into waitlist values(1,1,1);
select * from waitlist;

select * from student;

\qecho ''
\qecho 'Deleting entry from student to check cascade deletion'
delete from student where sid=1;

select * from student;
select * from enroll;
select * from waitlist;

\qecho 'Not deleting any entries from hastaken since we want to retain historic data'
\qecho ''

\qecho 'Defining delete trigger on course table for cascade delete'
CREATE OR REPLACE FUNCTION cascade_delete_on_course() RETURNS trigger AS
$$
BEGIN
 delete from prerequisite where cno=old.cno or prereq=old.cno;
 delete from enroll where cno=old.cno;
 delete from waitlist where cno=old.cno;
 RETURN old;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER cascade_delete_on_course_trigger
BEFORE DELETE
ON course
FOR EACH ROW
EXECUTE PROCEDURE cascade_delete_on_course();

select * from student;
insert into student values(1,'Sanket','DS');
select * from course c;

insert into enroll values(1,1);
select * from enroll;

insert into waitlist values(1,1,1);
select * from waitlist;

select * from course;
\qecho ''
\qecho 'Deleting entry from student to check cascade deletion'
delete from course where cno=1;

select * from course;
select * from prerequisite;
select * from enroll;
select * from waitlist;

\qecho ''
\qecho 'Not deleting any entries from hastaken since we want to retain historic data'
\qecho ''

drop trigger cascade_delete_on_course_trigger on course;
drop trigger cascade_delete_on_student_trigger on student;

\qecho ''
\qecho 'Question 1 c'
\qecho ''


\qecho ''
\qecho 'Defining delete or update restriction trigger on hastaken table'
CREATE OR REPLACE FUNCTION restrict_delete_or_update_on_hastaken() RETURNS trigger AS
$$
BEGIN
 RAISE EXCEPTION 'No delete or update allowed on hastaken';
 RETURN null;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER restrict_delete_or_update_on_hastaken_trigger
BEFORE delete or update
ON hastaken 
FOR EACH ROW
EXECUTE PROCEDURE restrict_delete_or_update_on_hastaken();

insert into course values(1,'ADC',50,60);
select * from hastaken;
insert into hastaken values(1,1);
delete from hastaken where true;
select * from hastaken;

create table check_flag(val boolean);
insert into check_flag values(true);
select * from check_flag;
update check_flag set val=true where true;
\qecho 'flag set to true means hastaken can insert values otherwise insertion restricted on hastaken table'

truncate table hastaken;
insert into hastaken values(1,1);
select * from hastaken; 

\qecho ''
\qecho 'Defining insert trigger on enroll table'
CREATE OR REPLACE FUNCTION insert_on_enroll() RETURNS trigger AS
$$
BEGIN
 update check_flag set val=false where true;
 RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER insert_on_enroll_trigger
BEFORE insert
ON enroll 
EXECUTE PROCEDURE insert_on_enroll();

select * from check_flag;
insert into enroll values(1,1);
select * from check_flag;

\qecho ''
\qecho 'Defining insert trigger on hastaken table'
CREATE OR REPLACE FUNCTION insert_on_hastaken() RETURNS trigger AS
$$
BEGIN
 IF (SELECT val FROM check_flag where true) THEN
    RETURN NEW;
 else
 raise exception 'Students have started getting enrolled in courses, can not insert new entries into has taken table';
 END IF;
 RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER insert_on_hastaken_trigger
BEFORE insert
ON hastaken 
for each row
EXECUTE PROCEDURE insert_on_hastaken();

select * from check_flag;
insert into hastaken values(1,1);
select * from check_flag;

drop trigger insert_on_enroll_trigger on enroll;
drop trigger restrict_delete_or_update_on_hastaken_trigger on hastaken;
drop trigger insert_on_hastaken_trigger on hastaken;



\qecho ''
\qecho 'Question 1 d'
\qecho ''
\qecho 'Defining delete or update restriction trigger on course table'
CREATE OR REPLACE FUNCTION restrict_delete_or_update_on_course() RETURNS trigger AS
$$
BEGIN
 RAISE EXCEPTION 'No delete or update allowed on course';
 RETURN null;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER restrict_delete_or_update_on_course_trigger
BEFORE delete or update
ON course 
EXECUTE PROCEDURE restrict_delete_or_update_on_course();

select * from course;
delete from course;
select * from course;

\qecho ''
\qecho 'Defining delete or update restriction trigger on prerequisite table'
CREATE OR REPLACE FUNCTION restrict_delete_or_update_on_prerequisite() RETURNS trigger AS
$$
BEGIN
 RAISE EXCEPTION 'No delete or update allowed on prerequisite';
 RETURN null;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER restrict_delete_or_update_on_prerequisite_trigger
BEFORE delete or update
ON prerequisite 
EXECUTE PROCEDURE restrict_delete_or_update_on_prerequisite();

insert into prerequisite values(1,1);
select * from prerequisite;
delete from prerequisite;
select * from prerequisite;

drop trigger restrict_delete_or_update_on_course_trigger on course;
drop trigger restrict_delete_or_update_on_prerequisite_trigger on prerequisite;


\qecho ''
\qecho 'Question 2'
\qecho ''


\qecho 'Defining insert trigger on enroll table for all validation'
CREATE OR REPLACE FUNCTION check_for_enroll() RETURNS trigger AS
$$
BEGIN
--if prerequistes are not fulfilled, raise error
 if exists(select * from prerequisite p where p.cno=new.cno and p.prereq not in(select h.cno from hastaken h where h.sid=new.sid))
 then 
 RAISE EXCEPTION 'Student has not taken prerequisites for this course';
--if max enrollment reached, then put into waitlist and raise error
 elseif
 exists(select * from course c where c.cno=new.cno and c.max<=c.total)
 then
	 if(select max(position) from waitlist where cno=new.cno) is null 
	 then
	 insert into waitlist values(new.sid,new.cno, 1);
	 else
	 insert into waitlist values(new.sid,new.cno, (select max(position)+1 from waitlist where cno=new.cno));
	 end if;
 --select 'Enrollment already full for this course, Student placed in waitlist for this course';
--otherwise if all goes well, increment total enrolled value for the course
 	RETURN Null;
 else
 update course set total=total+1 where cno=new.cno;
 return new;
 END IF;
RETURN Null;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER check_for_enroll_trigger
BEFORE INSERT
ON enroll
FOR EACH ROW
EXECUTE PROCEDURE check_for_enroll();

insert into course values(2,'AA',1,2);
insert into course values(3,'ML',1,2),(4,'AI',1,2);
update prerequisite set cno=2 where cno=1;
select * from prerequisite;
insert into prerequisite values(3,4);
select * from hastaken;

truncate table enroll;
insert into enroll values(1,3);
select * from enroll;
\qecho 'Gives error since student 1 for course 3 has not taken some prerequisite and hence denied enrollment'


insert into student values(2,'abc','CS');
insert into student values(3,'xyz','INFO');
select * from student;
select * from course;

insert into enroll values(1,4);
select * from course;
select * from prerequisite p2;
insert into enroll values(2,4);
select * from waitlist;
\qecho 'Since course is already full, entry is inserted into waitlist table'



\qecho 'Defining delete trigger on waitlist table'

CREATE OR REPLACE FUNCTION delete_on_waitlist() RETURNS trigger AS
$$
begin
--after deleting someone from waitlist, we need to restructure the positions for all the students 
 update waitlist set position=position-1 where cno=old.cno and position>old.position;
 RETURN Null;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER delete_on_waitlist_trigger
after DELETE
ON waitlist 
FOR EACH ROW
EXECUTE PROCEDURE delete_on_waitlist();

insert into enroll values(1,4);
select * from waitlist;
delete from waitlist where cno=4 and position=1;
select * from waitlist;


\qecho 'Defining delete trigger on enroll table'



CREATE OR REPLACE FUNCTION delete_on_enroll() RETURNS trigger AS
$$
begin
--after deleting a student from enroll, we must decrease total course enrollment value by 1
 update course set total=total-1 where cno=old.cno;
--if someone is on the waitlist, insert first waitlisted student into enroll table and delete that student from waitlist 
 if exists(select * from waitlist where cno=old.cno)
 then
 insert into enroll
(select w.sid,w.cno from waitlist w where w.cno=old.cno and w.position=(select min(position) from waitlist where w.cno=old.cno));
 delete from waitlist w where w.cno=old.cno and position=(select min(position) from waitlist where cno=old.cno);
 end if;
 RETURN Null;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER delete_on_enroll_trigger
after DELETE
ON enroll 
FOR EACH ROW
EXECUTE PROCEDURE delete_on_enroll();

select * from course;
select * from enroll;
select * from waitlist;

delete from enroll where sid=1;
\qecho 'List is restructured after sid 1 is deleted and positions of all waitlisted students is adjusted'


drop trigger check_for_enroll_trigger on enroll;
drop trigger delete_on_enroll_trigger on enroll;
drop trigger delete_on_waitlist_trigger on waitlist;


--For the third question, took help from one of my colleagues(Neha Pai).
\qecho ''
\qecho 'Question 3'
\qecho ''

\qecho 'Creating approximation table to store latest expected and variance'
create table approximation
(
expected_value float8,
variance_value float8
);
insert into approximation values(0,0);

create table random_value
(
val int,
num_trials int
);

\qecho 'Creating runExperiment function'
create or replace function runExperiment(k int)
returns table (expected_value float8,
variance_value float8)
as
$$
declare i int;
begin
for i in 1..k loop
insert into random_value values (floor(random()*6)+1 + floor(random()*6)+1 +floor(random()*6)+1,i);
end loop;
return query(select a.expected_value,sqrt(a.variance_value) from approximation a);
end;
$$ language plpgsql;

\qecho 'Creating function to calculate new values'
create or replace function calculate_approximation() RETURNS trigger AS
$$
declare old_mean float8;
declare old_var float8;
begin
old_mean=(select expected_value from approximation);
old_var=(select variance_value from approximation);
update approximation set
expected_value = ((old_mean * (new.num_trials-1)) + new.val)/(new.num_trials);
update approximation set
variance_value= ((new.num_trials-1)/new.num_trials::numeric) * (old_var + 
(power(old_mean - new.val,2)/new.num_trials)
);
RETURN Null;
END;
$$ LANGUAGE 'plpgsql';
--update approximation set
--select ((4-1)/4::numeric) * (0.666 + 
--(power(2-4,2)/4)
--);

\qecho 'Trigger for runExperiment function'
CREATE TRIGGER calculate_approximation_trigger
before INSERT
ON random_value 
FOR EACH ROW
EXECUTE PROCEDURE calculate_approximation();

\qecho 'Running experiment for n=10'
select (runExperiment(10)).expected_value, (runExperiment(10)).variance_value;

\qecho 'Running experiment for n=100'
select (runExperiment(100)).expected_value, (runExperiment(100)).variance_value;

\qecho 'Running experiment for n=1000'
select (runExperiment(1000)).expected_value, (runExperiment(1000)).variance_value;


\c postgres;
drop database sp;


