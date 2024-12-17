-- before start Run this :
--=========================
set serveroutput on; -- to show output on Script Output


-- delete all rows from specific tables
create or replace procedure ResetDB is
begin
    delete from AUDITTRAIL; 
    delete from borrowingrecords;  
    delete from notificationlogs;
    delete from penalties;  
end;

create or replace procedure CleanAllDB is
begin
    delete from AUDITTRAIL; 
    delete from borrowingrecords;  
    delete from notificationlogs;
    delete from penalties;
    delete from books;
    delete from booktypes;
    delete from students;
end;

create or replace procedure InsertBooksAndStudents is
begin
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
    
    insert into students values
    (1,'Osama Ahmed','Active'),
    (2,'Ahmed Alaa','Active'),
    (3,'Ahmed Nabil','Active'),
    (4,'Kareem Tarek','Active'),
    (5,'Ahmed Mahmoud','Active'),
    (6,'Adham Basel','Active'),
    (7,'Ramez Emad','Active');
    
end;

/*update book availability when inserting or updating in borrowingrecord table*/
create or replace trigger Track_BookAvailability
after insert or update on BORROWINGRECORDS
for each row
declare
    newStatus varchar2(20);
    bookId int;
begin
    if inserting then
        if((:new.status = 'on time') OR (:new.status = 'overdue')) then
            newStatus := 'Available';
        else
            newStatus := 'borrowed';
        end if;
        
    elsif updating then
        if((:new.status = 'on time') OR (:new.status = 'overdue')) then
            newStatus := 'Available';
        else
            newStatus := 'borrowed';
        end if;
    end if;
    
    bookId := :new.book_id;
    
    update books set book_availability = newStatus where book_id = bookId;
end;

------------------------------------------------------------------------------------

-- 1)
/*
this procedure take student id then check overdue or borrowed books for this student and count overdays
*/
create or replace procedure Student_OverdueDays(studentId int)
is

    countOfBooksOverdues int;
    overdays int;
    currentdate DATE;
    rowsnum int;
    
begin

    -- get num of book that are borrowed from a specif user_id
    select count(*) into countOfBooksOverdues from BORROWINGRECORDS where student_id = studentId AND (status = 'borrowed' OR status = 'overdue');
    
    if(countOfBooksOverdues > 0) then
    
        select CURRENT_DATE into currentdate from dual; -- to get current date 
        
        -- iterate over books that its satus 'borrowed' OR 'overdue' for a specific student
        for borrow in (select * from BORROWINGRECORDS where student_id = studentId AND (status = 'borrowed' OR status = 'overdue'))
        loop
            overdays := currentdate - borrow.return_date;
            
            -- give a penalty
            if(overdays > 7) then
            
                select NVL(max(notification_id), 0) into rowsnum from NOTIFICATIONLOGS; -- just to get next notificationlogs ID
                
                -- this if condition used to prevent duplicates in NOTIFICATIONLOGS
                if(IsRowExist(borrow.student_id, borrow.book_id) = 0) then            
                    insert into NOTIFICATIONLOGS values(rowsnum + 1, borrow.student_id, borrow.book_id, overdays - 7, currentdate);
                end if;
           
            -- student still in the legal period
            else
                DBMS_OUTPUT.PUT_LINE('No Overdue Days');
            end if;
       
        end loop;
        
    -- there is no borrowed or overdue books for this student ID    
    else 
        DBMS_OUTPUT.PUT_LINE('No Overdue Days');
    end if;
    
end;


-- Helper Function [prevent duplicates of rows]
CREATE OR REPLACE FUNCTION IsRowExist(studentId int, bookId int) 
RETURN int

IS

   numOfRows int;
   isexist int;
   
BEGIN

   select count(*) into numOfRows from NOTIFICATIONLOGS where student_id = studentId AND book_id = bookId;
   
   if(numOfRows > 0) then isexist :=1;
   else isexist := 0;
   end if;
   
   return isexist;
   
END;






--Test EXample--

exec ResetDB;

insert into borrowingrecords values (1,3,1,TO_DATE('2024-11-30', 'YYYY-MM-DD'), TO_DATE('2024-12-1', 'YYYY-MM-DD'), 'on time');
insert into borrowingrecords values (2,5,1,TO_DATE('2024-11-30', 'YYYY-MM-DD'), TO_DATE('2024-12-1', 'YYYY-MM-DD'), 'borrowed');
insert into borrowingrecords values (3,10,3,TO_DATE('2024-11-23', 'YYYY-MM-DD'), TO_DATE('2024-11-27', 'YYYY-MM-DD'), 'on time');
insert into borrowingrecords values (4,1,2,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-11-26', 'YYYY-MM-DD'), 'borrowed');
insert into borrowingrecords values (5,9,2,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-11-26', 'YYYY-MM-DD'), 'overdue');

exec Student_OverdueDays(1);
exec Student_OverdueDays(2);

select * from BORROWINGRECORDS;
select * from NOTIFICATIONLOGS;






----------------------------------------------------------------------------------------

--2)
/*
this function takes borrow record id then calculate late fee amount

if status of book is 'on time' then late fee amount is 0
if status of book is 'overdue' then get late fee amount from penalties table
if status of book is 'borrowed' then 
    if it still in legal period, late fee amount is 0
    else calculate late fee amount by equation in function and insert into penalties table
    
this function return late fee amount
*/
CREATE OR REPLACE FUNCTION CalculateLateFee(borrowRecordId int) 
RETURN NUMBER
IS    

    overdays NUMBER;
    latedays int;
    currentdate DATE;
    returndate DATE;
    borrowstatus varchar(20);
    feecost NUMBER;
    latefeeamount NUMBER;
    bookid int;
    studentid int;
    rowsnum int;
    
BEGIN
    select CURRENT_DATE into currentdate from dual; -- return current date
    
    select return_date, book_id, status into returndate, bookid, borrowstatus from BORROWINGRECORDS where borrow_id = borrowRecordId;
    
    if(borrowstatus = 'borrowed') then -- calculate it by the followed logic
        overdays := currentdate - returndate; -- get over days
        
        -- give a penalty
        if(overdays > 7) then
            latedays := overdays - 7;
            
            -- get fee of book from BOOKTYPES table
            select bt.fee_rate into feecost
            from BORROWINGRECORDS br
            inner join BOOKS bk on bk.book_id = br.book_id
            inner join BOOKTYPES bt on bt.booktype_id = bk.booktype_id
            where bk.book_id = bookid;
            
            -- equation to generate Late Fee Amount
            latefeeamount := latedays * (feecost/10); 
            
            select NVL(max(penalty_id), 0) into rowsnum from PENALTIES; -- to get next PENALTIES ID
            
            select student_id into studentid from BORROWINGRECORDS where borrow_id = borrowRecordId; -- get student ID
            
            insert into PENALTIES values (rowsnum + 1, studentid, latefeeamount, 'late');
            
        else -- still in the legal period
            latefeeamount := 0; 
        end if;
    
    elsif(borrowstatus = 'on time') then -- returned the book during the legal period
        latefeeamount := 0;
    
    elsif(borrowstatus = 'overdue') then -- retrun the amount from PENALTIES table
        select student_id into studentid from BORROWINGRECORDS where borrow_id = borrowRecordId;  
        
        select pn.amount
        into latefeeamount
        from PENALTIES pn
        inner join BORROWINGRECORDS br on br.student_id = pn.student_id
        where pn.student_id = studentid and br.status = 'overdue';
    
    end if;
    

    return latefeeamount;
    
END;

--Test EXample--

exec ResetDB;

insert into borrowingrecords values (1,3,1,TO_DATE('2024-11-30', 'YYYY-MM-DD'), TO_DATE('2024-12-1', 'YYYY-MM-DD'), 'on time');
insert into borrowingrecords values (2,5,1,TO_DATE('2024-11-30', 'YYYY-MM-DD'), TO_DATE('2024-12-1', 'YYYY-MM-DD'), 'borrowed');
insert into borrowingrecords values (3,10,3,TO_DATE('2024-11-23', 'YYYY-MM-DD'), TO_DATE('2024-11-27', 'YYYY-MM-DD'), 'on time');
insert into borrowingrecords values (4,1,2,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-12-12', 'YYYY-MM-DD'), 'borrowed');
insert into borrowingrecords values (5,4,3,TO_DATE('2024-11-30', 'YYYY-MM-DD'), TO_DATE('2024-12-1', 'YYYY-MM-DD'), 'overdue');
insert into borrowingrecords values (6,8,4,TO_DATE('2024-11-18', 'YYYY-MM-DD'), TO_DATE('2024-11-30', 'YYYY-MM-DD'), 'overdue');
insert into penalties values (1,3,25.65,'Late');
insert into penalties values (2,4,18.5,'Late');



begin
    DBMS_OUTPUT.PUT_LINE('Late Fee for recorde [1] = ' || CalculateLateFee(1));
    DBMS_OUTPUT.PUT_LINE('Late Fee for recorde [2] = ' || CalculateLateFee(2));
    DBMS_OUTPUT.PUT_LINE('Late Fee for recorde [3] = ' || CalculateLateFee(3));
    DBMS_OUTPUT.PUT_LINE('Late Fee for recorde [4] = ' || CalculateLateFee(4));
    DBMS_OUTPUT.PUT_LINE('Late Fee for recorde [5] = ' || CalculateLateFee(5));
    DBMS_OUTPUT.PUT_LINE('Late Fee for recorde [6] = ' || CalculateLateFee(6));
end;

select * from BORROWINGRECORDS;
select * from penalties;
select * from books;
select * from booktypes;




---------------------------------------------------------------------------------------

--3)

/*
this trigger prevent student from borrowing books if :
    - student has borrowed 3 books
    - student has an ovedue book

if this two cases happened then raise an error
*/

create or replace trigger Prevent_Borrowing
before insert on BORROWINGRECORDS
for each row
declare
        overdue int;
        numofborrow int;
        currentdate DATE;
        overdays int;
        rowsnum int;
begin
        select CURRENT_DATE into currentdate from dual; -- current date
        
        -- return how many time specific student borrowed books
        select count(*) into numofborrow from BORROWINGRECORDS where student_id = :new.student_id AND status = 'borrowed';
        if(numofborrow >= 3) then -- more than 3 books not allowed
             RAISE_APPLICATION_ERROR(-20001, 'You have reached the max limit of borrow!'); -- raise system error
        end if;
        
    
        --check if that student have overdue book or not
      select count(*) into rowsnum from BORROWINGRECORDS where student_id = :new.student_id AND status = 'overdue';
      if(rowsnum = 1) then -- overdue book (found)
         RAISE_APPLICATION_ERROR(-20002, 'You cannot borrow any book due to overdue books!'); -- raise system error
      end if;
end;





--Test EXample--

exec ResetDB;

-- test1)
insert into borrowingrecords values (1,5,2,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-12-10', 'YYYY-MM-DD'), 'borrowed');
insert into borrowingrecords values (2,6,2,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-12-10', 'YYYY-MM-DD'), 'borrowed');
insert into borrowingrecords values (3,7,2,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-12-10', 'YYYY-MM-DD'), 'borrowed');
insert into borrowingrecords values (4,8,2,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-12-10', 'YYYY-MM-DD'), 'borrowed');

--test2)
insert into borrowingrecords values (5,1,1,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-11-27', 'YYYY-MM-DD'), 'overdue');
insert into borrowingrecords values (6,2,1,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-12-2', 'YYYY-MM-DD'), 'overdue');


select * from borrowingrecords;


-----------------------------------------------------------------------------------------------------------------------------------------

--4)

/*
this trigger look for transaction that made on BORROWINGRECORD table (insert, update, delete)
then add info about this transaction into AUDITTRAIL table
*/
create or replace trigger Track_BorrowRecord
before insert or update or delete on BORROWINGRECORDS
for each row
declare
    rowsnum int;
begin
    select NVL(max(audit_id),0) into rowsnum from AUDITTRAIL; -- to get next aduit_id
    
    -- UPDATE
    if updating then
        insert into AUDITTRAIL 
        values (
            rowsnum + 1, 
            'BORROWINGRECORDS', 
            'Updating', 
            'borrow id: ' || :old.borrow_id || 
            ' book_id: ' || :old.book_id || 
            ' student_id: ' || :old.student_id || 
            ' borrow_date: ' || :old.borrow_date || 
            ' return_date: ' || :old.return_date || 
            ' status: ' || :old.status, 
            'borrow id: ' || :new.borrow_id || 
            ' book_id: ' || :new.book_id || 
            ' student_id: ' || :new.student_id || 
            ' borrow_date: ' || :new.borrow_date || 
            ' return_date: ' || :new.return_date || 
            ' status: ' || :new.status, 
            SYSDATE -- currrent date
        );
        
    --DELETE
    elsif deleting then
        insert into AUDITTRAIL 
        values (
            rowsnum + 1, 
            'BORROWINGRECORDS', 
            'Deleting', 
            'borrow id: ' || :old.borrow_id || 
            ' book_id: ' || :old.book_id || 
            ' student_id: ' || :old.student_id || 
            ' borrow_date: ' || :old.borrow_date || 
            ' return_date: ' || :old.return_date || 
            ' status: ' || :old.status, 
            null, -- new values DELETED
            SYSDATE -- currrent date
        );
        
    -- INSERT
     elsif inserting then
        insert into AUDITTRAIL 
        values (
            rowsnum + 1, 
            'BORROWINGRECORDS', 
            'Inserting',
            null, -- old values NOT exist already
            'borrow id: ' || :new.borrow_id || 
            ' book_id: ' || :new.book_id || 
            ' student_id: ' || :new.student_id || 
            ' borrow_date: ' || :new.borrow_date || 
            ' return_date: ' || :new.return_date || 
            ' status: ' || :new.status,  
            SYSDATE -- currrent date
        );

    end if;
end;


--Test EXample--

exec ResetDB;

insert into BORROWINGRECORDS values (1,3,1,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-12-10', 'YYYY-MM-DD'),'on time');
update BORROWINGRECORDS set status = 'overdue' where borrow_id = 1;
delete from BORROWINGRECORDS where borrow_id = 1;

select * from AUDITTRAIL;

---------------------------------------------------------------------------------------------------

--5)

/*
this procedure take student id and show all books that are 'overdue' or 'on time' for this student

we used cursor to handle this task
*/

create or replace procedure Get_BorrowInfo_Books(studentId int) as
    
    -- create cursor
    cursor Borrow_History_Cursor is
        select 
            br.book_id, 
            br.student_id, 
            br.borrow_date, 
            br.return_date, 
            br.status, 
            p.penalty_id, 
            p.amount, 
            p.reason
        from 
            BORROWINGRECORDS br
        left join 
            PENALTIES p 
            on br.student_id = p.student_id
        where 
            (br.status = 'on time' or br.status = 'overdue') and (br.student_id = studentId);
            
        bookId int;
        IdOfStudent int;
        borrowDate date; 
        returnDate date;
        borrowStatus varchar(20); 
        penaltyId int;
        amountPenalty Number(10,2); 
        lateReason varchar(225);
    
begin
    
    -- open cursor
    open Borrow_History_Cursor;
    loop
    
        -- fetch cursor 
        fetch Borrow_History_Cursor into bookId, IdOfStudent, borrowDate, returnDate, borrowStatus, penaltyId, amountpenalty, lateReason;

        exit when Borrow_History_Cursor%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('Book ID: ' || bookId);
        DBMS_OUTPUT.PUT_LINE('Student ID: ' || studentId);
        DBMS_OUTPUT.PUT_LINE('Borrow Date: ' || borrowDate);
        DBMS_OUTPUT.PUT_LINE('Return Date: ' || returnDate);
        DBMS_OUTPUT.PUT_LINE('Status: ' || borrowStatus);
        
        -- if the books' status is overdue then get some info from PENALTIES table and print it 
        if(borrowStatus = 'overdue') then
            
            DBMS_OUTPUT.PUT_LINE('Penalty ID: ' || penaltyId);
            DBMS_OUTPUT.PUT_LINE('Penalty Amount: ' || amountPenalty);
            DBMS_OUTPUT.PUT_LINE('Reason: ' || lateReason);
            
        end if;
        DBMS_OUTPUT.PUT_LINE('------------------');    
    end loop;
    
    -- close cursor
    close Borrow_History_Cursor;
end;




--Test EXample--

exec ResetDB;

insert into BORROWINGRECORDS values (1,3,1,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-12-11', 'YYYY-MM-DD'),'on time');
insert into BORROWINGRECORDS values (2,1,1,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-12-9', 'YYYY-MM-DD'),'overdue');
insert into BORROWINGRECORDS values (3,5,2,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-12-10', 'YYYY-MM-DD'),'on time');
insert into PENALTIES values (1,1,20,'Late');


select * from BORROWINGRECORDS;
select * from PENALTIES;


exec Get_BorrowInfo_Books(1);
exec Get_BorrowInfo_Books(2);
exec Get_BorrowInfo_Books(3);



-------------------------------------------------------------------------------------------------------

--6)

/*take borrow id and new status to update this field*/
create or replace procedure update_borrowing_status(borrowingId IN int , newStatus IN BorrowingRecords.status%TYPE)
is
begin
    UPDATE borrowingrecords SET status = newstatus
        where borrow_id = borrowingId;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'ID does not exist.');
    END IF;
end;


/*
take borrow id to return the book of this borrow id

check for penalty cost to know the new status of this borrowing info
*/
create or replace procedure return_book(borrowing_Id IN int )
is
penalty_cost NUMBER;
begin
    penalty_cost := calculatelatefee(borrowing_id);
    IF penalty_cost != 0 then
        update_borrowing_status(borrowing_id , 'overdue');
    else
        update_borrowing_status(borrowing_id , 'on time');
    end if;
end;



--Test EXample--

exec ResetDB;


insert into borrowingrecords values (1,3,1,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-11-27', 'YYYY-MM-DD'), 'on time');
insert into borrowingrecords values (2,10,1,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-11-27', 'YYYY-MM-DD'), 'overdue');
insert into borrowingrecords values (3,4,3,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-11-27', 'YYYY-MM-DD'), 'borrowed');
insert into borrowingrecords values (4,1,2,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-11-26', 'YYYY-MM-DD'), 'borrowed');
insert into borrowingrecords values (5,5,2,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-12-12', 'YYYY-MM-DD'), 'borrowed');
commit;

BEGIN 
    return_book(0); -- not exist
    return_book(3);

    DBMS_OUTPUT.PUT_LINE('Updated successfully. ');
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred. ');
        ROLLBACK;
end;


select * from borrowingrecords;
select * from penalties;



-------------------------------------------------------------------------------------------------------

--7)

/*
show all info about all books and show student id, name if the book is borrowed by this student and show overdue days if exist
*/
declare
    bookId int;
    bookTitle varchar(225);
    bookAuthor varchar(225);
    bookAvailability varchar(20);
    bookTypeId int;
    bookTypeName varchar(225);
    feeRate Number(10,2);
    borrowId int;
    returnDate date;
    studentId int;
    studentName varchar(225);
    overdays int;
    currentDate date;
begin
    
    -- get all books 
    for rowRecord in 
    (select b.book_id, b.title, b.author, b.book_availability, b.booktype_id, bt.type_name, bt.fee_rate, s.student_id, s.student_name, br.return_date
    from BOOKS b 
    inner join BOOKTYPES bt on bt.booktype_id = b.booktype_id
    left join BORROWINGRECORDS br on br.book_id = b.book_id
    left join STUDENTS s on s.student_id = br.student_id order by b.book_id)
    
    loop
        -- assigning variables
        bookId := rowRecord.book_id;
        bookTitle := rowRecord.title;
        bookAuthor := rowRecord.author;
        bookAvailability := rowRecord.book_availability;
        bookTypeId := rowRecord.booktype_id;
        bookTypeName := rowRecord.type_name;
        feeRate := rowRecord.fee_rate;
        studentId := rowRecord.student_id;
        studentName := rowRecord.student_name;
        returnDate := rowRecord.return_date;
        
        if(bookAvailability = 'overdue' OR bookAvailability = 'borrowed') then
            select CURRENT_DATE into currentDate from dual;
            overdays := currentDate - returnDate;
            if(overdays > 7) then
                DBMS_OUTPUT.PUT_LINE('===== Borrowing Record Report =====');
                DBMS_OUTPUT.PUT_LINE('Book Details:');
                DBMS_OUTPUT.PUT_LINE('   Book ID: ' || bookId);
                DBMS_OUTPUT.PUT_LINE('   Title: ' || bookTitle);
                DBMS_OUTPUT.PUT_LINE('   Author: ' || bookAuthor);
                DBMS_OUTPUT.PUT_LINE('   Book Type ID: ' || bookTypeId);
                DBMS_OUTPUT.PUT_LINE('   Book Type Name: ' || bookTypeName);
                DBMS_OUTPUT.PUT_LINE('   Availability: ' || bookAvailability);                       
                DBMS_OUTPUT.PUT_LINE('   Fee Rate: $' || feeRate);
            
                DBMS_OUTPUT.PUT_LINE('~~~~~~~~~~~~~~~~~~~~~~');
            
                DBMS_OUTPUT.PUT_LINE('Student Details:');
                DBMS_OUTPUT.PUT_LINE('   Student ID: ' || studentId);
                DBMS_OUTPUT.PUT_LINE('   Name: ' || studentName);
                DBMS_OUTPUT.PUT_LINE('   Overdue Days: ' || (overdays - 7));
                
                DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
            else
                DBMS_OUTPUT.PUT_LINE('===== Borrowing Record Report =====');
                DBMS_OUTPUT.PUT_LINE('Book Details:');
                DBMS_OUTPUT.PUT_LINE('   Book ID: ' || bookId);
                DBMS_OUTPUT.PUT_LINE('   Title: ' || bookTitle);
                DBMS_OUTPUT.PUT_LINE('   Author: ' || bookAuthor);
                DBMS_OUTPUT.PUT_LINE('   Book Type ID: ' || bookTypeId);
                DBMS_OUTPUT.PUT_LINE('   Book Type Name: ' || bookTypeName);
                DBMS_OUTPUT.PUT_LINE('   Availability: ' || bookAvailability);                       
                DBMS_OUTPUT.PUT_LINE('   Fee Rate: $' || feeRate);
            
                DBMS_OUTPUT.PUT_LINE('~~~~~~~~~~~~~~~~~~~~~~');
            
                DBMS_OUTPUT.PUT_LINE('Student Details:');
                DBMS_OUTPUT.PUT_LINE('   Student ID: ' || studentId);
                DBMS_OUTPUT.PUT_LINE('   Name: ' || studentName);
                DBMS_OUTPUT.PUT_LINE('   Overdue Days: ' || 'Still in legal period');
                
                DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
            end if;
        else
            DBMS_OUTPUT.PUT_LINE('===== Borrowing Record Report =====');
                DBMS_OUTPUT.PUT_LINE('Book Details:');
                DBMS_OUTPUT.PUT_LINE('   Book ID: ' || bookId);
                DBMS_OUTPUT.PUT_LINE('   Title: ' || bookTitle);
                DBMS_OUTPUT.PUT_LINE('   Author: ' || bookAuthor);
                DBMS_OUTPUT.PUT_LINE('   Book Type ID: ' || bookTypeId);
                DBMS_OUTPUT.PUT_LINE('   Book Type Name: ' || bookTypeName);
                DBMS_OUTPUT.PUT_LINE('   Availability: ' || bookAvailability);                       
                DBMS_OUTPUT.PUT_LINE('   Fee Rate: $' || feeRate);
                
                DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
        end if;            
        DBMS_OUTPUT.PUT_LINE('');
    end loop;
end;


--Test Example--

exec ResetDB;
exec CleanAllDB;
exec InsertBooksAndStudents;


insert into borrowingrecords values (1,2,1,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-11-27', 'YYYY-MM-DD'), 'borrowed');
insert into borrowingrecords values (2,10,5,TO_DATE('2024-11-22', 'YYYY-MM-DD'), TO_DATE('2024-11-30', 'YYYY-MM-DD'), 'borrowed');
insert into borrowingrecords values (4,9,3,TO_DATE('2024-12-2', 'YYYY-MM-DD'), TO_DATE('2024-12-12', 'YYYY-MM-DD'), 'borrowed');
insert into borrowingrecords values (5,8,6,TO_DATE('2024-11-30', 'YYYY-MM-DD'), TO_DATE('2024-12-1', 'YYYY-MM-DD'), 'overdue');
insert into borrowingrecords values (6,1,4,TO_DATE('2024-11-25', 'YYYY-MM-DD'), TO_DATE('2024-11-27', 'YYYY-MM-DD'), 'on time');


select * from books;
select * from borrowingrecords;
select * from booktypes;
select * from students;


    
-------------------------------------------------------------------------------------------------------

--8)

/* this procedure updating membership status of student from active to suspended if his penalties amount greater than 50 */
create or replace procedure Suspend_Students
as
begin
    for penalty in (select student_id, sum(amount) from PENALTIES group by student_id having sum(amount) > 50)
    loop
        update students set membership_status = 'Suspended' where student_id = penalty.student_id;
    end loop;
end;



--Test EXample--

exec ResetDB;
exec CleanAllDB;
exec InsertBooksAndStudents;

select * from PENALTIES;
select * from students;

insert into PENALTIES values (1,1, 60, 'The dog ate the book');
insert into PENALTIES values (2,2, 20, 'Iam broke');
insert into PENALTIES values (3,3, 30, 'Late');
insert into PENALTIES values (4,4, 200, 'No Reason');
insert into PENALTIES values (5,3, 30, 'Late');


exec Suspend_Students;

-------------------------------------------------------------------------------------------------------

-- 9)

-- in this task we will create user one and usertwo then give them privileges to create tables for userone and user one should give user two the privilege to
-- insert into those tables (books - booktypes)

-- create usermanager
CREATE USER UserManager IDENTIFIED BY 123;
GRANT DBA TO UserManager;

-- on usermanager conn
ALTER SESSION SET "_oracle_script"=true;
CREATE USER UserOne IDENTIFIED BY 123; 
GRANT CREATE TABLE TO UserOne;
GRANT CREATE SESSION TO UserOne;
GRANT CREATE SEQUENCE TO USERONE;
ALTER USER userone QUOTA 100M ON USERS;

-- create tables
-- on user1 conn
CREATE TABLE BookTypes (
    bookType_id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    type_name VARCHAR2(255) not null,
    fee_rate NUMBER(10, 2) not null
);

-- on user1 conn
CREATE TABLE Books (
    book_id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY ,
    title VARCHAR2(255) not null,
    author VARCHAR2(255) not null,
    book_availability VARCHAR2(20) not null,
    bookType_id int REFERENCES BookTypes(bookType_id)
);

--------------


-- delete from booktypes;
-- delete from books;


--------------
-- on manager conn
ALTER SESSION SET "_oracle_script"=true;
CREATE USER UserTwo IDENTIFIED BY 123; 
GRANT CREATE SESSION TO UserTwo;
ALTER USER usertwo QUOTA 100M ON USERS;

--on user1 conn
GRANT INSERT ON BookTypes TO UserTwo;
GRANT INSERT ON Books TO UserTwo;

drop table booktypes;
drop table books;
select * from books;
select * from booktypes;

-- on user2 conn
INSERT INTO "USERONE".BookTypes(type_name, fee_rate) VALUES ('Science Fiction', 12.50);
INSERT INTO "USERONE".BookTypes(type_name, fee_rate) VALUES ('Physics Fiction', 15);
INSERT INTO "USERONE".BookTypes(type_name, fee_rate) VALUES ('Novel', 20);

INSERT INTO "USERONE".Books (title,author,book_availability,bookType_id)
VALUES ('The Red Flower','Ahmed Alaa','avaliable',3);

INSERT INTO "USERONE".Books (title,author,book_availability,bookType_id)
VALUES ('The Blue Flower','Ahmed','avaliable',1);

INSERT INTO "USERONE".Books (title,author,book_availability,bookType_id)
VALUES ('The Green Flower','Alaa','unavaliable',1);

INSERT INTO "USERONE".Books (title,author,book_availability,bookType_id)
VALUES ('The Beautiful Flower','Mahmoud','unavaliable',2);

INSERT INTO "USERONE".Books (title,author,book_availability,bookType_id)
VALUES ('The IDK flower','IDK','avaliable',2);

COMMIT;



------------------------------------------------------------------------------------
-- 10)

-- in this task we are simulating a block waiting situation that happens when there is user trying to access table or update into it without
-- commit the changes while there is another user want to update the same table that makes block waiting situation between the two user


-- on userone conn
-- Session 1 (USER1) starts a transaction
-- go to useronepage and run the sql block
GRANT UPDATE,SELECT ON books TO usertwo; -- by user1
-- on usertwo conn
BEGIN
-- Session 2 (USER2) tries to update the same row in the Books table
UPDATE "USERONE".Books
SET book_availability = 'Available'
WHERE book_id = 4;

END;
--------------------------------------------------------------------------------
-- 11)

-- in this task we are trying to solve the previous situation but first we will get the details of the session that are blocking using v$session table by 
-- the usermanager then he will use sid and serial# to kill this session

-- go to usermanagerpage and kill the session
-------------------------------------------------------------------------------------
-- 12)
-- go to useronepage run the first block then come here run the first block num 12)
GRANT SELECT, UPDATE ON "USERONE".Books TO USERTWO;
GRANT SELECT, UPDATE ON "USERONE".BookTypes TO USERTWO;


BEGIN
    UPDATE "USERONE".BookTypes 
    SET fee_rate = 15.00
    WHERE bookType_id = 1;
EXCEPTION
    WHEN others THEN
        DBMS_OUTPUT.PUT_LINE('Deadlock detected.');
        ROLLBACK; 
END;

-- go again to useronepage run the second block then come here run the second block num 12)
BEGIN
    UPDATE "USERONE".Books 
    SET book_availability = 'Checked Out'
    WHERE book_id = 1;
EXCEPTION
    WHEN others THEN
        DBMS_OUTPUT.PUT_LINE('Deadlock detected.');
        ROLLBACK; 
END;


