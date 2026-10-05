# Library Management Database System

## 📌 Project Overview

A relational database system developed using MySQL to manage library users, books, book availability, and borrowing transactions.

## 🛠️ Technologies Used

- MySQL
- SQL
- MySQL Workbench

## ⚙️ Features

- User management
- Book management
- Book issuing
- Book returning
- Book availability tracking
- Transaction tracking
- Overdue fine calculation
- Borrowing history
- Library reports
- Stored procedures
- Database views

## 🗄️ Database Tables

### Users

The `users` table stores library member information such as:

- User ID
- Name
- Email
- Phone
- Address
- Membership Type
- Status
- Registration Date

### Books

The `books` table stores information about books such as:

- Book ID
- Title
- Author
- Category
- ISBN
- Publisher
- Publication Year
- Language
- Shelf Location
- Total Copies
- Available Copies

### Transactions

The `transactions` table stores book issue and return information such as:

- Transaction ID
- User ID
- Book ID
- Issue Date
- Due Date
- Return Date
- Status
- Fine Amount
- Renewal Count
- Remarks

## 🔗 Database Relationships

The `transactions` table connects users and books.

- One user can have multiple transactions.
- One book can have multiple transactions.
- `user_id` is a foreign key referencing the `users` table.
- `book_id` is a foreign key referencing the `books` table.

```text
Users
  |
  | 1
  |
  | M
Transactions
  |
  | M
  |
  | 1
Books

Library-Management-Database-System/
│
├── library_management.sql
├── README.md
│
└── screenshots/
    ├── database_tables.png
    ├── users_table.png
    ├── books_table.png
    ├── transactions_table.png
    ├── issued_books.png
    ├── transaction_report.png
    └── reports.png