import os
import psycopg2
from flask import Flask, request, render_template_string
import time

app = Flask(__name__)

# הגדרות התחברות לדאטה-בייס - קריאה ממשתני סביבה
DB_HOST = os.environ.get('DB_HOST', 'db')
DB_NAME = os.environ.get('POSTGRES_DB', 'myappdb')
DB_USER = os.environ.get('POSTGRES_USER', 'user')
DB_PASS = os.environ.get('POSTGRES_PASSWORD', 'password')

def get_db_connection():
    # מנסה להתחבר עד שה-DB מוכן
    retries = 5
    while retries > 0:
        try:
            conn = psycopg2.connect(
                host=DB_HOST,
                database=DB_NAME,
                user=DB_USER,
                password=DB_PASS
            )
            return conn
        except Exception as e:
            print(f"Waiting for DB... {e}")
            time.sleep(5)
            retries -= 1
    return None

def init_db():
    """יצירת הטבלה אם היא לא קיימת"""
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                username VARCHAR(50) NOT NULL,
                email VARCHAR(100) NOT NULL
            );
        """)
        conn.commit()
        cur.close()
        conn.close()
        print("Database initialized successfully.")

# אתחול ה-DB בעליית האפליקציה
init_db()

# ה-HTML של הדף (פשוט, כדי לא ליצור עוד קבצים)
HTML_FORM = """
<!doctype html>
<html dir="rtl">
<head><title>הרשמה לשירות</title></head>
<body>
    <h2>טופס הרשמה</h2>
    <form method="POST">
        שם משתמש: <input type="text" name="username" required><br><br>
        אימייל: <input type="email" name="email" required><br><br>
        <input type="submit" value="הירשם">
    </form>
    <hr>
    <h3>משתמשים רשומים במערכת:</h3>
    <ul>
    {% for user in users %}
        <li>{{ user[1] }} - {{ user[2] }}</li>
    {% endfor %}
    </ul>
</body>
</html>
"""

@app.route('/', methods=['GET', 'POST'])
def index():
    conn = get_db_connection()
    if not conn:
        return "Database Connection Error", 500
    
    cur = conn.cursor()

    if request.method == 'POST':
        username = request.form['username']
        email = request.form['email']
        cur.execute('INSERT INTO users (username, email) VALUES (%s, %s)', (username, email))
        conn.commit()

    cur.execute('SELECT * FROM users')
    users = cur.fetchall()
    cur.close()
    conn.close()
    
    return render_template_string(HTML_FORM, users=users)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
    