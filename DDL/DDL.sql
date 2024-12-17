CREATE TABLE AuditTrail (
    audit_id int PRIMARY KEY,
    table_name VARCHAR2(255) not null,
    operation VARCHAR2(20) not null,
    old_data CLOB,
    new_data CLOB,
    timestamp_operation TIMESTAMP not null
);


CREATE TABLE BookTypes (
    bookType_id int PRIMARY KEY,
    type_name VARCHAR2(255) not null,
    fee_rate NUMBER(10, 2) not null
);


CREATE TABLE Books (
    book_id int PRIMARY KEY,
    title VARCHAR2(255) not null,
    author VARCHAR2(255) not null,
    book_availability VARCHAR2(20) not null,
    bookType_id int REFERENCES BookTypes(bookType_id)
);


CREATE TABLE Students (
    student_id int PRIMARY KEY,
    student_name VARCHAR2(255) not null,
    membership_status VARCHAR2(20) not null
);

-- Creating the BorrowingRecords table
CREATE TABLE BorrowingRecords (
    borrow_id int PRIMARY KEY,
    book_id int REFERENCES Books(book_id),
    student_id int REFERENCES Students(student_id),
    borrow_date DATE not null,
    return_date DATE not null,
    status VARCHAR2(20) not null
);


CREATE TABLE Penalties (
    penalty_id int PRIMARY KEY,
    student_id int REFERENCES Students(student_id),
    amount NUMBER(10,2) not null,
    reason VARCHAR2(255) not null
);




CREATE TABLE NotificationLogs (
    notification_id int PRIMARY KEY,
    student_id int REFERENCES Students(student_id),
    book_id int REFERENCES Books(book_id),
    overdue_days int not null,
    notification_date DATE not null
);




