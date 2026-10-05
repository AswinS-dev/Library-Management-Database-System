-- ============================================================
-- LIBRARY MANAGEMENT DATABASE SYSTEM
-- Project 2
-- Technologies: MySQL, SQL, Relational Database
-- ============================================================

-- ============================================================
-- 1. CREATE DATABASE
-- ============================================================

DROP DATABASE IF EXISTS library_management;

CREATE DATABASE library_management;

USE library_management;


-- ============================================================
-- 2. CREATE USERS TABLE
-- ============================================================

CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(15) NOT NULL UNIQUE,
    registration_date DATE NOT NULL DEFAULT (CURRENT_DATE)
);


-- ============================================================
-- 3. CREATE BOOKS TABLE
-- ============================================================

CREATE TABLE books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(150) NOT NULL,
    author VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    isbn VARCHAR(20) UNIQUE,
    total_copies INT NOT NULL DEFAULT 1,
    available_copies INT NOT NULL DEFAULT 1,

    CONSTRAINT chk_total_copies
        CHECK (total_copies > 0),

    CONSTRAINT chk_available_copies
        CHECK (
            available_copies >= 0
            AND available_copies <= total_copies
        )
);


-- ============================================================
-- 4. CREATE TRANSACTIONS TABLE
-- ============================================================

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,

    user_id INT NOT NULL,
    book_id INT NOT NULL,

    issue_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    due_date DATE NOT NULL,
    return_date DATE NULL,

    status ENUM('Issued', 'Returned') NOT NULL DEFAULT 'Issued',

    CONSTRAINT fk_transaction_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_transaction_book
        FOREIGN KEY (book_id)
        REFERENCES books(book_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_due_date
        CHECK (due_date >= issue_date),

    CONSTRAINT chk_return_date
        CHECK (
            return_date IS NULL
            OR return_date >= issue_date
        )
);


-- ============================================================
-- 5. INSERT SAMPLE USERS
-- ============================================================

INSERT INTO users
(name, email, phone)
VALUES
('Ashwin', 'ashwin@gmail.com', '9876543210'),
('Arun', 'arun@gmail.com', '9876543211'),
('Karthik', 'karthik@gmail.com', '9876543212'),
('Rahul', 'rahul@gmail.com', '9876543213'),
('Priya', 'priya@gmail.com', '9876543214');


-- ============================================================
-- 6. INSERT SAMPLE BOOKS
-- ============================================================

INSERT INTO books
(title, author, category, isbn, total_copies, available_copies)
VALUES
('Clean Code',
 'Robert C. Martin',
 'Programming',
 '9780132350884',
 5,
 5),

('Java: The Complete Reference',
 'Herbert Schildt',
 'Java',
 '9781260440232',
 4,
 4),

('SQL Fundamentals',
 'John Smith',
 'Database',
 '9781234567890',
 3,
 3),

('HTML and CSS',
 'Jon Duckett',
 'Web Development',
 '9781118008188',
 4,
 4),

('The Alchemist',
 'Paulo Coelho',
 'Novel',
 '9780061122415',
 3,
 3),

('Computer Networks',
 'Andrew S. Tanenbaum',
 'Networking',
 '9780132126953',
 2,
 2),

('Operating System Concepts',
 'Abraham Silberschatz',
 'Operating System',
 '9781118063330',
 3,
 3),

('Data Structures and Algorithms',
 'Thomas H. Cormen',
 'Computer Science',
 '9780262046305',
 4,
 4);


-- ============================================================
-- 7. BASIC VIEW QUERIES
-- ============================================================

-- View all users
SELECT * FROM users;

-- View all books
SELECT * FROM books;

-- View all transactions
SELECT * FROM transactions;


-- ============================================================
-- 8. BOOK MANAGEMENT QUERIES
-- ============================================================

-- ------------------------------------------------------------
-- 8.1 Add a new book
-- ------------------------------------------------------------

INSERT INTO books
(title, author, category, isbn, total_copies, available_copies)
VALUES
('Spring Boot in Action',
 'Craig Walls',
 'Java',
 '9781617292545',
 3,
 3);


-- ------------------------------------------------------------
-- 8.2 View books
-- ------------------------------------------------------------

SELECT
    book_id,
    title,
    author,
    category,
    isbn,
    total_copies,
    available_copies
FROM books;


-- ------------------------------------------------------------
-- 8.3 Search book by title
-- ------------------------------------------------------------

SELECT *
FROM books
WHERE title LIKE '%Java%';


-- ------------------------------------------------------------
-- 8.4 Search book by author
-- ------------------------------------------------------------

SELECT *
FROM books
WHERE author LIKE '%Robert%';


-- ------------------------------------------------------------
-- 8.5 Search book by category
-- ------------------------------------------------------------

SELECT *
FROM books
WHERE category = 'Programming';


-- ------------------------------------------------------------
-- 8.6 Show available books
-- ------------------------------------------------------------

SELECT
    book_id,
    title,
    author,
    category,
    available_copies
FROM books
WHERE available_copies > 0;


-- ------------------------------------------------------------
-- 8.7 Update book information
-- ------------------------------------------------------------

UPDATE books
SET category = 'Programming'
WHERE book_id = 1;


-- ------------------------------------------------------------
-- 8.8 Increase copies of a book
-- ------------------------------------------------------------

UPDATE books
SET
    total_copies = total_copies + 2,
    available_copies = available_copies + 2
WHERE book_id = 1;


-- ============================================================
-- 9. USER MANAGEMENT QUERIES
-- ============================================================

-- ------------------------------------------------------------
-- 9.1 Add a new user
-- ------------------------------------------------------------

INSERT INTO users
(name, email, phone)
VALUES
('Vijay', 'vijay@gmail.com', '9876543215');


-- ------------------------------------------------------------
-- 9.2 View all users
-- ------------------------------------------------------------

SELECT *
FROM users
ORDER BY user_id;


-- ------------------------------------------------------------
-- 9.3 Search user by name
-- ------------------------------------------------------------

SELECT *
FROM users
WHERE name LIKE '%Ashwin%';


-- ------------------------------------------------------------
-- 9.4 Search user by email
-- ------------------------------------------------------------

SELECT *
FROM users
WHERE email = 'ashwin@gmail.com';


-- ------------------------------------------------------------
-- 9.5 Update user phone
-- ------------------------------------------------------------

UPDATE users
SET phone = '9000000000'
WHERE user_id = 1;


-- ============================================================
-- 10. ISSUE BOOK - STORED PROCEDURE
-- ============================================================

DROP PROCEDURE IF EXISTS issue_book;

DELIMITER $$

CREATE PROCEDURE issue_book(
    IN p_user_id INT,
    IN p_book_id INT,
    IN p_days INT
)
BEGIN

    DECLARE v_user_exists INT DEFAULT 0;
    DECLARE v_book_exists INT DEFAULT 0;
    DECLARE v_available_copies INT DEFAULT 0;
    DECLARE v_existing_issue INT DEFAULT 0;

    -- Rollback automatically if unexpected SQL error occurs
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Validate loan period
    IF p_days <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Loan period must be greater than zero.';
    END IF;


    START TRANSACTION;


    -- Check user
    SELECT COUNT(*)
    INTO v_user_exists
    FROM users
    WHERE user_id = p_user_id;


    IF v_user_exists = 0 THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User does not exist.';

    END IF;


    -- Check book
    SELECT COUNT(*)
    INTO v_book_exists
    FROM books
    WHERE book_id = p_book_id;


    IF v_book_exists = 0 THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Book does not exist.';

    END IF;


    -- Lock book row while checking availability
    SELECT available_copies
    INTO v_available_copies
    FROM books
    WHERE book_id = p_book_id
    FOR UPDATE;


    -- Check availability
    IF v_available_copies <= 0 THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Book is currently unavailable.';

    END IF;


    -- Prevent same user from borrowing same book twice
    SELECT COUNT(*)
    INTO v_existing_issue
    FROM transactions
    WHERE user_id = p_user_id
      AND book_id = p_book_id
      AND status = 'Issued';


    IF v_existing_issue > 0 THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'This user already has this book issued.';

    END IF;


    -- Create transaction
    INSERT INTO transactions
    (
        user_id,
        book_id,
        issue_date,
        due_date,
        status
    )
    VALUES
    (
        p_user_id,
        p_book_id,
        CURDATE(),
        DATE_ADD(CURDATE(), INTERVAL p_days DAY),
        'Issued'
    );


    -- Decrease available copies
    UPDATE books
    SET available_copies = available_copies - 1
    WHERE book_id = p_book_id;


    COMMIT;


    SELECT
        'Book issued successfully.' AS message;

END $$

DELIMITER ;


-- ============================================================
-- 11. RETURN BOOK - STORED PROCEDURE
-- ============================================================

DROP PROCEDURE IF EXISTS return_book;

DELIMITER $$

CREATE PROCEDURE return_book(
    IN p_transaction_id INT
)
BEGIN

    DECLARE v_transaction_exists INT DEFAULT 0;
    DECLARE v_book_id INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;


    START TRANSACTION;


    -- Check active transaction
    SELECT COUNT(*)
    INTO v_transaction_exists
    FROM transactions
    WHERE transaction_id = p_transaction_id
      AND status = 'Issued';


    IF v_transaction_exists = 0 THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Active issued transaction does not exist.';

    END IF;


    -- Get book ID
    SELECT book_id
    INTO v_book_id
    FROM transactions
    WHERE transaction_id = p_transaction_id
      AND status = 'Issued'
    FOR UPDATE;


    -- Update transaction
    UPDATE transactions
    SET
        return_date = CURDATE(),
        status = 'Returned'
    WHERE transaction_id = p_transaction_id;


    -- Increase available copies
    UPDATE books
    SET available_copies = available_copies + 1
    WHERE book_id = v_book_id;


    COMMIT;


    SELECT
        'Book returned successfully.' AS message;

END $$

DELIMITER ;


-- ============================================================
-- 12. ISSUE BOOK - EXAMPLE
-- ============================================================

-- User 1 borrows Book 1 for 14 days

CALL issue_book(1, 1, 14);


-- ============================================================
-- 13. ISSUE ANOTHER BOOK - EXAMPLE
-- ============================================================

-- User 2 borrows Book 2 for 7 days

CALL issue_book(2, 2, 7);


-- ============================================================
-- 14. VIEW CURRENTLY ISSUED BOOKS
-- ============================================================

SELECT
    t.transaction_id,
    u.user_id,
    u.name AS user_name,
    b.book_id,
    b.title AS book_title,
    t.issue_date,
    t.due_date,
    t.status
FROM transactions t
JOIN users u
    ON t.user_id = u.user_id
JOIN books b
    ON t.book_id = b.book_id
WHERE t.status = 'Issued'
ORDER BY t.issue_date DESC;


-- ============================================================
-- 15. VIEW COMPLETE TRANSACTION HISTORY
-- ============================================================

SELECT
    t.transaction_id,
    u.name AS user_name,
    b.title AS book_title,
    t.issue_date,
    t.due_date,
    t.return_date,
    t.status
FROM transactions t
JOIN users u
    ON t.user_id = u.user_id
JOIN books b
    ON t.book_id = b.book_id
ORDER BY t.transaction_id DESC;


-- ============================================================
-- 16. RETURN BOOK - EXAMPLE
-- ============================================================

-- Return transaction number 1

CALL return_book(1);


-- ============================================================
-- 17. USER BORROWING HISTORY
-- ============================================================

SELECT
    u.user_id,
    u.name AS user_name,
    b.title AS book_title,
    t.issue_date,
    t.due_date,
    t.return_date,
    t.status
FROM transactions t
JOIN users u
    ON t.user_id = u.user_id
JOIN books b
    ON t.book_id = b.book_id
WHERE u.user_id = 1
ORDER BY t.issue_date DESC;


-- ============================================================
-- 18. BOOK BORROWING HISTORY
-- ============================================================

SELECT
    b.book_id,
    b.title,
    u.name AS borrowed_by,
    t.issue_date,
    t.return_date,
    t.status
FROM transactions t
JOIN books b
    ON t.book_id = b.book_id
JOIN users u
    ON t.user_id = u.user_id
WHERE b.book_id = 1
ORDER BY t.issue_date DESC;


-- ============================================================
-- 19. COUNT CURRENTLY ISSUED BOOKS
-- ============================================================

SELECT
    COUNT(*) AS total_issued_books
FROM transactions
WHERE status = 'Issued';


-- ============================================================
-- 20. COUNT RETURNED BOOKS
-- ============================================================

SELECT
    COUNT(*) AS total_returned_books
FROM transactions
WHERE status = 'Returned';


-- ============================================================
-- 21. TOTAL TRANSACTIONS
-- ============================================================

SELECT
    COUNT(*) AS total_transactions
FROM transactions;


-- ============================================================
-- 22. MOST BORROWED BOOKS
-- ============================================================

SELECT
    b.book_id,
    b.title,
    COUNT(t.transaction_id) AS times_borrowed
FROM books b
LEFT JOIN transactions t
    ON b.book_id = t.book_id
GROUP BY
    b.book_id,
    b.title
ORDER BY times_borrowed DESC;


-- ============================================================
-- 23. MOST ACTIVE USERS
-- ============================================================

SELECT
    u.user_id,
    u.name,
    COUNT(t.transaction_id) AS total_borrowings
FROM users u
LEFT JOIN transactions t
    ON u.user_id = t.user_id
GROUP BY
    u.user_id,
    u.name
ORDER BY total_borrowings DESC;


-- ============================================================
-- 24. BOOKS NEVER BORROWED
-- ============================================================

SELECT
    b.book_id,
    b.title,
    b.author
FROM books b
LEFT JOIN transactions t
    ON b.book_id = t.book_id
WHERE t.transaction_id IS NULL;


-- ============================================================
-- 25. OVERDUE BOOKS
-- ============================================================

SELECT
    t.transaction_id,
    u.name AS user_name,
    b.title AS book_title,
    t.issue_date,
    t.due_date
FROM transactions t
JOIN users u
    ON t.user_id = u.user_id
JOIN books b
    ON t.book_id = b.book_id
WHERE t.status = 'Issued'
  AND t.due_date < CURDATE();


-- ============================================================
-- 26. BOOKS WITH LOW AVAILABILITY
-- ============================================================

SELECT
    book_id,
    title,
    total_copies,
    available_copies
FROM books
WHERE available_copies <= 1;


-- ============================================================
-- 27. BOOK COUNT BY CATEGORY
-- ============================================================

SELECT
    category,
    COUNT(*) AS number_of_books,
    SUM(total_copies) AS total_copies,
    SUM(available_copies) AS available_copies
FROM books
GROUP BY category
ORDER BY number_of_books DESC;


-- ============================================================
-- 28. USERS WHO CURRENTLY HAVE BOOKS
-- ============================================================

SELECT DISTINCT
    u.user_id,
    u.name,
    u.email
FROM users u
JOIN transactions t
    ON u.user_id = t.user_id
WHERE t.status = 'Issued';


-- ============================================================
-- 29. USERS WHO HAVE NEVER BORROWED A BOOK
-- ============================================================

SELECT
    u.user_id,
    u.name,
    u.email
FROM users u
LEFT JOIN transactions t
    ON u.user_id = t.user_id
WHERE t.transaction_id IS NULL;


-- ============================================================
-- 30. VIEW: AVAILABLE BOOKS
-- ============================================================

DROP VIEW IF EXISTS available_books;

CREATE VIEW available_books AS
SELECT
    book_id,
    title,
    author,
    category,
    total_copies,
    available_copies
FROM books
WHERE available_copies > 0;


-- Test the view

SELECT *
FROM available_books;


-- ============================================================
-- 31. VIEW: CURRENTLY ISSUED BOOKS
-- ============================================================

DROP VIEW IF EXISTS issued_books;

CREATE VIEW issued_books AS
SELECT
    t.transaction_id,
    u.user_id,
    u.name AS user_name,
    b.book_id,
    b.title AS book_title,
    t.issue_date,
    t.due_date,
    t.status
FROM transactions t
JOIN users u
    ON t.user_id = u.user_id
JOIN books b
    ON t.book_id = b.book_id
WHERE t.status = 'Issued';


-- Test the view

SELECT *
FROM issued_books;


-- ============================================================
-- 32. VIEW: COMPLETE TRANSACTION REPORT
-- ============================================================

DROP VIEW IF EXISTS transaction_report;

CREATE VIEW transaction_report AS
SELECT
    t.transaction_id,
    u.name AS user_name,
    u.email,
    b.title AS book_title,
    b.author,
    t.issue_date,
    t.due_date,
    t.return_date,
    t.status
FROM transactions t
JOIN users u
    ON t.user_id = u.user_id
JOIN books b
    ON t.book_id = b.book_id;


-- Test the view

SELECT *
FROM transaction_report;


-- ============================================================
-- 33. DATABASE SUMMARY
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM books) AS total_book_titles,

    (SELECT COALESCE(SUM(total_copies), 0)
     FROM books) AS total_book_copies,

    (SELECT COALESCE(SUM(available_copies), 0)
     FROM books) AS available_book_copies,

    (SELECT COUNT(*) FROM users) AS total_users,

    (SELECT COUNT(*)
     FROM transactions
     WHERE status = 'Issued') AS currently_issued_books,

    (SELECT COUNT(*)
     FROM transactions
     WHERE status = 'Returned') AS returned_books;


-- ============================================================
-- 34. FINAL DATABASE CHECK
-- ============================================================

SHOW TABLES;

SELECT * FROM users;

SELECT * FROM books;

SELECT * FROM transactions;

-- ============================================================
-- END OF PROJECT
-- ============================================================