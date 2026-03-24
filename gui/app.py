from flask import Flask, render_template, request, redirect, url_for, flash, session
from datetime import datetime
from functools import wraps
import oracledb

app = Flask(__name__)
app.secret_key = "bank-project-secret-key"

# Database connection settings
DB_USER = "YOUR_USERNAME"
DB_PASSWORD = "YOUR_PASSWORD"
DB_HOST = "localhost"
DB_PORT = 1521
DB_SERVICE = "YOUR_SERVICE_NAME"


def get_connection():
    dsn = f"{DB_HOST}:{DB_PORT}/{DB_SERVICE}"
    return oracledb.connect(user=DB_USER, password=DB_PASSWORD, dsn=dsn)


def login_required(route_function):
    @wraps(route_function)
    def wrapper(*args, **kwargs):
        if "active_person_ptal" not in session:
            flash("Please log in first.", "warning")
            return redirect(url_for("login"))
        return route_function(*args, **kwargs)
    return wrapper


def admin_required(route_function):
    @wraps(route_function)
    def wrapper(*args, **kwargs):
        if "active_person_ptal" not in session:
            flash("Please log in first.", "warning")
            return redirect(url_for("login"))

        if not session.get("is_admin"):
            flash("You do not have access to the admin page.", "danger")
            return redirect(url_for("home"))

        return route_function(*args, **kwargs)
    return wrapper


def get_active_person():
    active_ptal = session.get("active_person_ptal")
    if not active_ptal:
        return None

    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.execute(
            """
            SELECT P_Tal, FirstName, LastName
            FROM Person
            WHERE P_Tal = :p_tal
            """,
            {"p_tal": active_ptal},
        )
        return cursor.fetchone()
    finally:
        cursor.close()
        connection.close()


def is_employee(person_ptal):
    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.execute(
            """
            SELECT COUNT(*)
            FROM Employee
            WHERE P_Tal = :p_tal
            """,
            {"p_tal": person_ptal},
        )
        count = cursor.fetchone()[0]
        return count > 0
    finally:
        cursor.close()
        connection.close()


def get_all_people():
    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.execute(
            """
            SELECT P_Tal, FirstName, LastName
            FROM Person
            ORDER BY FirstName, LastName
            """
        )
        return cursor.fetchall()
    finally:
        cursor.close()
        connection.close()


def get_all_customers():
    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.execute(
            """
            SELECT customer.P_Tal,
                   person.FirstName,
                   person.LastName
            FROM Customer customer
            JOIN Person person
                ON customer.P_Tal = person.P_Tal
            ORDER BY person.FirstName, person.LastName
            """
        )
        return cursor.fetchall()
    finally:
        cursor.close()
        connection.close()


def get_all_accounts():
    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.execute(
            """
            SELECT AccountNumber
            FROM Account
            ORDER BY AccountNumber
            """
        )
        return [row[0] for row in cursor.fetchall()]
    finally:
        cursor.close()
        connection.close()


def get_account_types():
    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.execute(
            """
            SELECT AccountTypeId, TypeName
            FROM AccountType
            ORDER BY AccountTypeId
            """
        )
        return cursor.fetchall()
    finally:
        cursor.close()
        connection.close()


def get_relationship_types():
    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.execute(
            """
            SELECT RelationshipTypeId, TypeName
            FROM RelationshipType
            ORDER BY RelationshipTypeId
            """
        )
        return cursor.fetchall()
    finally:
        cursor.close()
        connection.close()


def get_accessible_accounts(person_ptal):
    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.execute(
            """
            SELECT
                account.AccountNumber,
                ownerPerson.FirstName || ' ' || ownerPerson.LastName AS OwnerName,
                accountType.TypeName AS AccountType,
                account.Balance,
                account.AllowedOverdraft,
                1 AS CanView,
                1 AS CanTransfer,
                'Owner' AS AccessSource
            FROM Account account
            JOIN Customer customer
                ON account.CustomerPTal = customer.P_Tal
            JOIN Person ownerPerson
                ON customer.P_Tal = ownerPerson.P_Tal
            JOIN AccountType accountType
                ON account.AccountTypeId = accountType.AccountTypeId
            WHERE account.CustomerPTal = :person_ptal

            UNION

            SELECT
                account.AccountNumber,
                ownerPerson.FirstName || ' ' || ownerPerson.LastName AS OwnerName,
                accountType.TypeName AS AccountType,
                account.Balance,
                account.AllowedOverdraft,
                accountAccess.CanView,
                accountAccess.CanTransfer,
                'Granted access' AS AccessSource
            FROM AccountAccess accountAccess
            JOIN Account account
                ON accountAccess.AccountNumber = account.AccountNumber
            JOIN Customer customer
                ON account.CustomerPTal = customer.P_Tal
            JOIN Person ownerPerson
                ON customer.P_Tal = ownerPerson.P_Tal
            JOIN AccountType accountType
                ON account.AccountTypeId = accountType.AccountTypeId
            WHERE accountAccess.PersonPTal = :person_ptal
              AND (accountAccess.EndDate IS NULL OR accountAccess.EndDate >= TRUNC(SYSDATE))

            ORDER BY AccountNumber
            """,
            {"person_ptal": person_ptal},
        )
        return cursor.fetchall()
    finally:
        cursor.close()
        connection.close()


def person_can_transfer_from_account(person_ptal, account_number):
    accessible_accounts = get_accessible_accounts(person_ptal)

    for account in accessible_accounts:
        if account[0] == account_number and account[6] == 1:
            return True

    return False


def person_can_view_account(person_ptal, account_number):
    accessible_accounts = get_accessible_accounts(person_ptal)

    for account in accessible_accounts:
        if account[0] == account_number and account[5] == 1:
            return True

    return False


@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        p_tal = request.form["p_tal"].strip()

        connection = get_connection()
        cursor = connection.cursor()

        try:
            cursor.execute(
                """
                SELECT P_Tal, FirstName, LastName
                FROM Person
                WHERE P_Tal = :p_tal
                """,
                {"p_tal": p_tal},
            )
            person = cursor.fetchone()

            if person:
                session["active_person_ptal"] = person[0]
                session["is_admin"] = is_employee(person[0])

                flash("Login successful.", "success")

                if session["is_admin"]:
                    return redirect(url_for("admin_dashboard"))
                else:
                    return redirect(url_for("home"))
            else:
                flash("No person found with that P-tal.", "danger")
        finally:
            cursor.close()
            connection.close()

    return render_template("login.html", active_person=None, is_admin=False)


@app.route("/logout", methods=["POST"])
def logout():
    session.clear()
    flash("You have been logged out.", "success")
    return redirect(url_for("login"))


@app.route("/home")
@login_required
def home():
    active_person = get_active_person()
    return render_template(
        "home.html",
        active_person=active_person,
        is_admin=session.get("is_admin", False),
    )


@app.route("/admin")
@admin_required
def admin_dashboard():
    active_person = get_active_person()

    return render_template(
        "admin.html",
        active_person=active_person,
        is_admin=True,
        people=get_all_people(),
        customers=get_all_customers(),
        accounts=get_all_accounts(),
        account_types=get_account_types(),
        relationship_types=get_relationship_types(),
    )


@app.route("/admin/create-person", methods=["POST"])
@admin_required
def admin_create_person():
    p_tal = request.form["p_tal"]
    first_name = request.form["first_name"]
    last_name = request.form["last_name"]
    zip_code = request.form["zip_code"]

    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.execute(
            """
            INSERT INTO Person (P_Tal, FirstName, LastName, Zip)
            VALUES (:p_tal, :first_name, :last_name, :zip_code)
            """,
            {
                "p_tal": p_tal,
                "first_name": first_name,
                "last_name": last_name,
                "zip_code": zip_code,
            },
        )
        connection.commit()
        flash("Person created successfully.", "success")
    except Exception as error:
        connection.rollback()
        flash(f"Error creating person: {error}", "danger")
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for("admin_dashboard"))


@app.route("/admin/create-customer", methods=["POST"])
@admin_required
def admin_create_customer():
    person_ptal = request.form["person_ptal"]
    comment_text = request.form["comment_text"]

    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.execute(
            """
            INSERT INTO Customer (P_Tal, CommentText)
            VALUES (:person_ptal, :comment_text)
            """,
            {
                "person_ptal": person_ptal,
                "comment_text": comment_text,
            },
        )
        connection.commit()
        flash("Customer created successfully.", "success")
    except Exception as error:
        connection.rollback()
        flash(f"Error creating customer: {error}", "danger")
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for("admin_dashboard"))


@app.route("/admin/create-account", methods=["POST"])
@admin_required
def admin_create_account():
    account_number = request.form["account_number"]
    balance = request.form["balance"]
    allowed_overdraft = request.form["allowed_overdraft"]
    created_date = request.form["created_date"]
    customer_ptal = request.form["customer_ptal"]
    account_type_id = request.form["account_type_id"]

    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.execute(
            """
            INSERT INTO Account (
                AccountNumber,
                Balance,
                AllowedOverdraft,
                CreatedDate,
                CustomerPTal,
                AccountTypeId
            )
            VALUES (
                :account_number,
                :balance,
                :allowed_overdraft,
                TO_DATE(:created_date, 'YYYY-MM-DD'),
                :customer_ptal,
                :account_type_id
            )
            """,
            {
                "account_number": account_number,
                "balance": balance,
                "allowed_overdraft": allowed_overdraft,
                "created_date": created_date,
                "customer_ptal": customer_ptal,
                "account_type_id": account_type_id,
            },
        )
        connection.commit()
        flash("Account created successfully.", "success")
    except Exception as error:
        connection.rollback()
        flash(f"Error creating account: {error}", "danger")
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for("admin_dashboard"))


@app.route("/admin/create-family-relation", methods=["POST"])
@admin_required
def admin_create_family_relation():
    person1_ptal = request.form["person1_ptal"]
    person2_ptal = request.form["person2_ptal"]
    relationship_type_id = request.form["relationship_type_id"]
    start_date = request.form["start_date"]
    end_date = request.form["end_date"]

    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.execute(
            """
            INSERT INTO FamilyRelation (
                Person1PTal,
                Person2PTal,
                StartDate,
                EndDate,
                RelationshipTypeId
            )
            VALUES (
                :person1_ptal,
                :person2_ptal,
                TO_DATE(:start_date, 'YYYY-MM-DD'),
                CASE
                    WHEN :end_date = '' THEN NULL
                    ELSE TO_DATE(:end_date, 'YYYY-MM-DD')
                END,
                :relationship_type_id
            )
            """,
            {
                "person1_ptal": person1_ptal,
                "person2_ptal": person2_ptal,
                "start_date": start_date,
                "end_date": end_date,
                "relationship_type_id": relationship_type_id,
            },
        )
        connection.commit()
        flash("Family relation created successfully.", "success")
    except Exception as error:
        connection.rollback()
        flash(f"Error creating family relation: {error}", "danger")
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for("admin_dashboard"))


@app.route("/admin/grant-access", methods=["POST"])
@admin_required
def admin_grant_access():
    person_ptal = request.form["person_ptal"]
    account_number = request.form["account_number"]
    can_view = request.form.get("can_view", "0")
    can_transfer = request.form.get("can_transfer", "0")
    start_date = request.form["start_date"]
    end_date = request.form["end_date"]

    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.execute(
            """
            INSERT INTO AccountAccess (
                PersonPTal,
                AccountNumber,
                CanView,
                CanTransfer,
                StartDate,
                EndDate
            )
            VALUES (
                :person_ptal,
                :account_number,
                :can_view,
                :can_transfer,
                TO_DATE(:start_date, 'YYYY-MM-DD'),
                CASE
                    WHEN :end_date = '' THEN NULL
                    ELSE TO_DATE(:end_date, 'YYYY-MM-DD')
                END
            )
            """,
            {
                "person_ptal": person_ptal,
                "account_number": account_number,
                "can_view": can_view,
                "can_transfer": can_transfer,
                "start_date": start_date,
                "end_date": end_date,
            },
        )
        connection.commit()
        flash("Account access granted successfully.", "success")
    except Exception as error:
        connection.rollback()
        flash(f"Error granting account access: {error}", "danger")
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for("admin_dashboard"))


@app.route("/admin/deposit", methods=["POST"])
@admin_required
def admin_deposit():
    account_number = request.form["account_number"]
    amount = request.form["amount"]
    description = request.form["description"]

    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.callproc("deposit_money", [account_number, float(amount), description])
        connection.commit()
        flash("Deposit completed successfully.", "success")
    except Exception as error:
        connection.rollback()
        flash(f"Error making deposit: {error}", "danger")
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for("admin_dashboard"))


@app.route("/admin/withdraw", methods=["POST"])
@admin_required
def admin_withdraw():
    account_number = request.form["account_number"]
    amount = request.form["amount"]
    description = request.form["description"]

    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.callproc("withdraw_money", [account_number, float(amount), description])
        connection.commit()
        flash("Withdrawal completed successfully.", "success")
    except Exception as error:
        connection.rollback()
        flash(f"Error making withdrawal: {error}", "danger")
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for("admin_dashboard"))


@app.route("/my-accounts")
@login_required
def my_accounts():
    if session.get("is_admin"):
        return redirect(url_for("admin_dashboard"))

    active_person = get_active_person()
    accounts = get_accessible_accounts(active_person[0])

    return render_template(
        "my_accounts.html",
        active_person=active_person,
        is_admin=False,
        accounts=accounts,
    )


@app.route("/draft-transfer", methods=["GET", "POST"])
@login_required
def create_draft_transfer():
    if session.get("is_admin"):
        return redirect(url_for("admin_dashboard"))

    active_person = get_active_person()
    accessible_accounts = get_accessible_accounts(active_person[0])
    from_accounts = [row for row in accessible_accounts if row[6] == 1]

    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.execute(
            """
            SELECT AccountNumber
            FROM Account
            ORDER BY AccountNumber
            """
        )
        all_accounts = [row[0] for row in cursor.fetchall()]
    finally:
        cursor.close()
        connection.close()

    if request.method == "POST":
        from_account = request.form["from_account"]
        to_account = request.form["to_account"]
        amount = request.form["amount"]
        transfer_date = request.form["transfer_date"]

        if not person_can_transfer_from_account(active_person[0], from_account):
            flash("You are not allowed to transfer from this account.", "danger")
            return redirect(url_for("create_draft_transfer"))

        connection = get_connection()
        cursor = connection.cursor()

        try:
            cursor.execute(
                """
                INSERT INTO DraftTransfer (
                    Amount,
                    TransferDate,
                    Status,
                    FromAccountNumber,
                    ToAccountNumber
                )
                VALUES (
                    :amount,
                    TO_DATE(:transfer_date, 'YYYY-MM-DD'),
                    'NEW',
                    :from_account,
                    :to_account
                )
                """,
                {
                    "amount": amount,
                    "transfer_date": transfer_date,
                    "from_account": from_account,
                    "to_account": to_account,
                },
            )
            connection.commit()
            flash("Draft transfer created successfully.", "success")
            return redirect(url_for("show_draft_transfers"))
        except Exception as error:
            connection.rollback()
            flash(f"Error creating draft transfer: {error}", "danger")
        finally:
            cursor.close()
            connection.close()

    return render_template(
        "create_draft_transfer.html",
        active_person=active_person,
        is_admin=False,
        from_accounts=from_accounts,
        all_accounts=all_accounts,
    )


@app.route("/draft-transfers")
@login_required
def show_draft_transfers():
    if session.get("is_admin"):
        return redirect(url_for("admin_dashboard"))

    active_person = get_active_person()
    accessible_accounts = get_accessible_accounts(active_person[0])
    accessible_account_numbers = [row[0] for row in accessible_accounts]

    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.execute(
            """
            SELECT DraftTransferId,
                   Amount,
                   TransferDate,
                   Status,
                   FromAccountNumber,
                   ToAccountNumber
            FROM DraftTransfer
            ORDER BY DraftTransferId
            """
        )
        all_drafts = cursor.fetchall()

        relevant_drafts = []
        for draft in all_drafts:
            if draft[4] in accessible_account_numbers or draft[5] in accessible_account_numbers:
                relevant_drafts.append(draft)

        return render_template(
            "draft_transfers.html",
            active_person=active_person,
            is_admin=False,
            draft_transfers=relevant_drafts,
        )
    finally:
        cursor.close()
        connection.close()


@app.route("/book-transfer/<int:draft_transfer_id>", methods=["POST"])
@login_required
def book_transfer(draft_transfer_id):
    if session.get("is_admin"):
        return redirect(url_for("admin_dashboard"))

    active_person = get_active_person()

    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.execute(
            """
            SELECT FromAccountNumber
            FROM DraftTransfer
            WHERE DraftTransferId = :draft_id
            """,
            {"draft_id": draft_transfer_id},
        )
        row = cursor.fetchone()

        if not row:
            flash("Draft transfer not found.", "danger")
            return redirect(url_for("show_draft_transfers"))

        from_account = row[0]

        if not person_can_transfer_from_account(active_person[0], from_account):
            flash("You are not allowed to book this transfer.", "danger")
            return redirect(url_for("show_draft_transfers"))

        cursor.callproc("book_draft_transfer", [draft_transfer_id])
        connection.commit()
        flash(f"Draft transfer {draft_transfer_id} booked successfully.", "success")

    except Exception as error:
        connection.rollback()
        flash(f"Error booking transfer: {error}", "danger")
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for("show_draft_transfers"))


@app.route("/account-statement", methods=["GET", "POST"])
@login_required
def account_statement():
    if session.get("is_admin"):
        return redirect(url_for("admin_dashboard"))

    active_person = get_active_person()
    accessible_accounts = get_accessible_accounts(active_person[0])
    viewable_accounts = [row for row in accessible_accounts if row[5] == 1]

    statement_rows = []
    selected_account = None
    account_info = None

    if request.method == "POST":
        selected_account = request.form["account_number"]

        if not person_can_view_account(active_person[0], selected_account):
            flash("You are not allowed to view this account.", "danger")
            return redirect(url_for("account_statement"))

        connection = get_connection()
        cursor = connection.cursor()

        try:
            cursor.execute(
                """
                SELECT account.AccountNumber,
                       account.Balance,
                       account.AllowedOverdraft,
                       accountType.TypeName
                FROM Account account
                JOIN AccountType accountType
                    ON account.AccountTypeId = accountType.AccountTypeId
                WHERE account.AccountNumber = :account_number
                """,
                {"account_number": selected_account},
            )
            account_info = cursor.fetchone()

            cursor.execute(
                """
                SELECT AccountNumber,
                       TransactionDate,
                       TransactionType,
                       Description,
                       Amount
                FROM AccountStatementView
                WHERE AccountNumber = :account_number
                ORDER BY TransactionDate
                """,
                {"account_number": selected_account},
            )
            statement_rows = cursor.fetchall()
        finally:
            cursor.close()
            connection.close()

    return render_template(
        "account_statement.html",
        active_person=active_person,
        is_admin=False,
        accounts=viewable_accounts,
        statement_rows=statement_rows,
        selected_account=selected_account,
        account_info=account_info,
    )


@app.route("/interest", methods=["GET", "POST"])
@login_required
def interest():
    active_person = get_active_person()

    if request.method == "POST":
        interest_date = datetime.strptime(
            request.form["interest_date"], "%Y-%m-%d"
        ).date()

        connection = get_connection()
        cursor = connection.cursor()

        try:
            cursor.callproc("calculate_monthly_interest", [interest_date])
            connection.commit()
            flash("Monthly interest calculated successfully.", "success")
        except Exception as error:
            connection.rollback()
            flash(f"Error calculating interest: {error}", "danger")
        finally:
            cursor.close()
            connection.close()

        if session.get("is_admin"):
            return redirect(url_for("admin_dashboard"))
        return redirect(url_for("interest"))

    return render_template(
        "interest.html",
        active_person=active_person,
        is_admin=session.get("is_admin", False),
    )


if __name__ == "__main__":
    app.run(debug=True)
