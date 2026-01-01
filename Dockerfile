# שימוש בגרסת פייתון קלה
FROM python:3.9-slim

# הגדרת תיקיית העבודה בתוך הקונטיינר
WORKDIR /app

# העתקת קובץ הדרישות והתקנת הספריות
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# העתקת שאר הקבצים
COPY . .

# חשיפת הפורט
EXPOSE 5000

# הפקודה שתריץ את האפליקציה
CMD ["python", "app.py"]