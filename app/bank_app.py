"""
Bank Management System - Python backend (CLI)
Requires: pip install oracledb
Edit DSN / USER / PASSWORD below. Business logic lives in the PL/SQL
procedures (05_plsql.sql) and triggers (02_triggers.sql).
"""
import oracledb

USER, PASSWORD, DSN = "bankuser", "password", "localhost/XEPDB1"


def connect():
    return oracledb.connect(user=USER, password=PASSWORD, dsn=DSN)


def add_customer(con, name, dob, phone, email, address):
    cur = con.cursor()
    cid = cur.var(int)
    cur.execute(
        """INSERT INTO Customer VALUES (seq_customer.NEXTVAL, :n, TO_DATE(:d,'YYYY-MM-DD'),
           :p, :e, :a) RETURNING customer_id INTO :cid""",
        n=name, d=dob, p=phone, e=email, a=address, cid=cid)
    con.commit()
    return cid.getvalue()[0]


def open_account(con, customer_id, branch_id, acc_type):
    cur = con.cursor()
    acc = cur.var(int)
    cur.execute(
        """INSERT INTO Account(account_no,customer_id,branch_id,acc_type)
           VALUES (seq_account.NEXTVAL,:c,:b,:t) RETURNING account_no INTO :a""",
        c=customer_id, b=branch_id, t=acc_type, a=acc)
    con.commit()
    return acc.getvalue()[0]


def balance(con, acc):
    cur = con.cursor()
    cur.execute("SELECT balance FROM Account WHERE account_no=:a", a=acc)
    row = cur.fetchone()
    return row[0] if row else None


def statement(con, acc, limit=10):
    cur = con.cursor()
    cur.execute("""SELECT txn_id, txn_type, amount, TO_CHAR(txn_date,'DD-MON-YY'), description
                   FROM Bank_Transaction WHERE account_no=:a
                   ORDER BY txn_date DESC, txn_id DESC FETCH FIRST :n ROWS ONLY""", a=acc, n=limit)
    return cur.fetchall()


def call(con, proc, *args):
    """Run a stored procedure; DB errors (e.g. insufficient balance) are returned as text."""
    try:
        con.cursor().callproc(proc, list(args))
        return "OK"
    except oracledb.DatabaseError as e:
        con.rollback()
        return str(e).split("\n")[0]


def loan_report(con):
    cur = con.cursor()
    cur.execute("SELECT * FROM v_loan_outstanding ORDER BY loan_id")
    return cur.fetchall()


MENU = """
1 Add customer      2 Open account     3 Deposit        4 Withdraw
5 Transfer          6 Balance          7 Statement      8 Pay loan
9 Loan report       0 Exit
"""


def main():
    con = connect()
    while True:
        print(MENU)
        ch = input("Choice: ").strip()
        if ch == "1":
            print("Customer ID:", add_customer(con, input("Name: "), input("DOB (YYYY-MM-DD): "),
                  input("Phone: "), input("Email: "), input("Address: ")))
        elif ch == "2":
            print("Account No:", open_account(con, int(input("Customer ID: ")),
                  int(input("Branch ID: ")), input("Type (SAVINGS/CURRENT/FIXED): ").upper()))
        elif ch == "3":
            print(call(con, "deposit", int(input("Account: ")), float(input("Amount: "))))
        elif ch == "4":
            print(call(con, "withdraw", int(input("Account: ")), float(input("Amount: "))))
        elif ch == "5":
            print(call(con, "transfer", int(input("From: ")), int(input("To: ")), float(input("Amount: "))))
        elif ch == "6":
            print("Balance:", balance(con, int(input("Account: "))))
        elif ch == "7":
            for r in statement(con, int(input("Account: "))):
                print(r)
        elif ch == "8":
            print(call(con, "pay_loan", int(input("Loan ID: ")), float(input("Amount: "))))
        elif ch == "9":
            for r in loan_report(con):
                print(r)
        elif ch == "0":
            break
    con.close()


if __name__ == "__main__":
    main()
