-- on userone conn
-- 10) 
BEGIN
-- Session 1 (userone) updates a row in the Books table, locking it
UPDATE "USERONE".Books
SET book_availability = 'Borrowed'
WHERE book_id = 4;

END;
-----------------------------------------------------------------------------
-- 12)

-- run this then go run the first block in tasks.sql num 12)
BEGIN
    UPDATE "USERONE".Books 
    SET book_availability = 'Available'
    WHERE book_id = 1;
EXCEPTION
    WHEN others THEN
        DBMS_OUTPUT.PUT_LINE('Deadlock detected.');
        ROLLBACK; 
END;

-- run this then go run the second block in tasks.sql num 12)
BEGIN 
    UPDATE "USERONE".BookTypes 
    SET type_name = 'Science Fiction'
    WHERE bookType_id = 1;
EXCEPTION
    WHEN others THEN
        DBMS_OUTPUT.PUT_LINE('Deadlock detected.');
        ROLLBACK; 
END;