

select * from students;


INSERT INTO booktypes (booktype_id, type_name, fee_rate)
VALUES 
    (1, 'Fiction', 25.50),
    (2, 'Non-Fiction', 30.00),
    (3, 'Science', 40.75),
    (4, 'History', 20.00),
    (5, 'Biography', 35.25),
    (6, 'Fantasy', 50.00),
    (7, 'Mystery', 45.00),
    (8, 'Romance', 22.50),
    (9, 'Thriller', 28.75);

select * from booktypes;


INSERT INTO books (book_id, title, author, book_availability, booktype_id)
VALUES 
    (1, 'Magic in the Air', 'Ahmed Tawfik', 'Available', 6),
    (2, 'The Great Adventure', 'Dan the Man', 'Available', 1),
    (3, 'The History of Time', 'Might guy', 'Available', 4),
    (4, 'Love and Loss', 'Nelson Mandela', 'Available', 8),
    (5, 'Life of a Leader', 'Nelson Mandela', 'Available', 5),
    (6, 'The Silent Night', 'Nageeb Mahfouz', 'Available', 7),
    (7, 'Exploring the Universe', 'Leo', 'Available', 3),   
    (8, 'Science for All', 'Jane Smith', 'Available', 2),
    (9, 'Into the Unknown', 'John Wick', 'Available', 9),
    (10, 'Adventure World', 'Finn', 'Available', 1);


select * from books;
delete from borrowingrecords;
insert into borrowingrecords values (1,3,1,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-11-27', 'YYYY-MM-DD'), 'on time');
insert into borrowingrecords values (2,10,1,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-11-27', 'YYYY-MM-DD'), 'overdue');
insert into borrowingrecords values (3,4,2,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-11-27', 'YYYY-MM-DD'), 'overdue');
insert into borrowingrecords values (4,1,2,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-11-26', 'YYYY-MM-DD'), 'overdue');
insert into borrowingrecords values (5,5,2,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-12-2', 'YYYY-MM-DD'), 'overdue');
insert into borrowingrecords values (6,6,2,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-12-2', 'YYYY-MM-DD'), 'overdue');
insert into borrowingrecords values (7,7,2,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-12-2', 'YYYY-MM-DD'), 'overdue');
insert into borrowingrecords values (8,8,2,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-12-2', 'YYYY-MM-DD'), 'overdue');
insert into borrowingrecords values (9,9,2,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-12-2', 'YYYY-MM-DD'), 'overdue');


delete from students;

insert into students values
(1,'Osama Ahmed','Active'),
(2,'Ahmed Alaa','Active'),
(3,'Ahmed Nabil','Active'),
(4,'Kareem Tarek','Active'),
(5,'Ahmed Mahmoud','Active'),
(6,'Adham Basel','Active'),
(7,'Ramez Emad','Active');

select * from students;



select * from borrowingrecords;


select * from penalties;

insert into penalties values (1,1,12,'dog ate the book');
insert into penalties values (2,2,30,'i have no money');



















select * from students;
select * from booktypes;
select * from books;
select * from borrowingrecords;
select * from notificationlogs;
select * from penalties;
select * from audittrail;




SELECT * 
FROM USER_TAB_PRIVS;


SELECT * 
FROM USER_SYS_PRIVS;

select user from dual;
