# Bank Database Project

This project implements a banking database system using Oracle SQL together with a Flask-based graphical user interface (GUI). The purpose of the project is to demonstrate database design, integrity constraints, business logic through triggers and stored procedures, and interaction with the database through a simple application interface.

The system supports management of persons, customers, accounts, account access permissions, draft transfers, transactions, and monthly interest calculation. The GUI is used to interact with and demonstrate the functionality of the database.

# Project Structure

The project is organized into three main parts:
	•	sql/: Contains all SQL scripts required to build the database
	•	gui/: Contains the Flask application used as the graphical interface
	•	docs/: Contains diagrams and screenshots used for documentation

  # Database Setup

  The database must be created by executing the SQL scripts in the correct order. It is important that the database is empty before starting.

Run the following files step-by-step in this exact order:
	1.	1_create_tables.sql
	2.	2_insert_constraints.sql
	3.	3_insert_lookup_data.sql
	4.	4_validate_ptal_function.sql
	5.	5_insert_triggers.sql
	6.	6_insert_test_data.sql
	7.	8_views.sql
	8.	9_procedures.sql

Each script depends on the previous ones, so running them out of order will cause errors.

# Running the GUI

To run the graphical interface, follow these steps:

First, install the required Python packages:

pip install -r requirements.txt

Then open the file gui/app.py and update the database connection settings so they match your local Oracle setup:

DB_USER = “YOUR_USERNAME”
DB_PASSWORD = “YOUR_PASSWORD”
DB_HOST = “localhost”
DB_PORT = 1521
DB_SERVICE = “YOUR_SERVICE_NAME”

After updating the connection settings, navigate to the gui folder and start the application:

python app.py

Then open a browser and go to:

http://127.0.0.1:5000/

# Login

The system uses P-tal as login. No password is required.

Example users:

Petur – 030375-009 (Admin)
Anna – 110580-126 (Customer)
Sara – 090988-018 (Limited access)

# Roles

The system distinguishes between two types of users:

Admin (Employee):
The admin user represents internal bank staff and has full access to the system. The admin can create persons, customers, and accounts, grant access permissions, create family relations, and perform deposits and withdrawals.

Customer:
Customers can only access functionality related to their own accounts or accounts they have been granted access to. They can view accounts, create draft transfers, book transfers if permitted, view account statements, and calculate interest.

# Main Features

Constraints:
The database uses foreign keys and other constraints to ensure referential integrity and enforce valid relationships between tables.

Triggers:
Triggers are used to enforce business rules such as validating P-tal format, preventing invalid data, and ensuring that transaction dates are not set in the future.

Views:
Views are used to present structured and readable data, including account statements and transaction overviews.

Stored Procedures:
The system includes stored procedures for core operations such as deposit_money, withdraw_money, book_draft_transfer, and calculate_monthly_interest.

# Rebuilding the Project

To rebuild the entire project from scratch:
	1.	Drop all existing tables and objects
	2.	Run the SQL scripts in the correct order
	3.	Start the GUI
	4.	Log in and test the system

  
