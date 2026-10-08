import mysql.connector

CONFIG = dict(host="localhost", user="root", password="password", database="bank_db")


def connect():
    return mysql.connector.connect(**CONFIG)


def add_customer(con, name, dob, phone, email, address):
    cur = con.cursor()
    cur.execute("INSERT INTO Customer (name, dob, phone, email, address) VALUES (%s,%s,%s,%s,%s)",
                (name, dob, phone, email, address))
    con.commit()
    return cur.lastrowid


def open_account(con, customer_id, branch_id, acc_type):
    cur = con.cursor()
    cur.execute("INSERT INTO Account (customer_id, branch_id, acc_type) VALUES (%s,%s,%s)",
                (customer_id, branch_id, acc_type))
    con.commit()
    return cur.lastrowid


def balance(con, acc):
    cur = con.cursor()
    cur.execute("SELECT balance FROM Account WHERE account_no=%s", (acc,))
    row = cur.fetchone()
    return row[0] if row else None


def statement(con, acc, limit=10):
    cur = con.cursor()
    cur.execute("""SELECT txn_id, txn_type, amount, DATE_FORMAT(txn_date,'%d-%b-%y'), description
                   FROM Bank_Transaction WHERE account_no=%s
                   ORDER BY txn_date DESC, txn_id DESC LIMIT %s""", (acc, limit))
    return cur.fetchall()


def call(con, proc, *args):
    """Run a stored procedure; database errors (e.g. insufficient balance) come back as text."""
    try:
        cur = con.cursor()
        cur.callproc(proc, args)
        con.commit()
        return "OK"
    except mysql.connector.Error as e:
        con.rollback()
        return e.msg


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
