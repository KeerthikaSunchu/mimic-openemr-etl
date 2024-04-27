from faker import Faker
import mysql.connector

# Set up Faker and the MySQL connection
fake = Faker()
conn = mysql.connector.connect(user='root', password='password',
                              host='localhost',
                              database='openemr')
cursor = conn.cursor()

# SQL to select the patient's gender
select_sql = "SELECT pid, sex FROM patient_data"

# SQL to update the patient's name
update_sql = "UPDATE patient_data SET fname=%s, lname=%s WHERE pid=%s"

cursor.execute(select_sql)
patients = cursor.fetchall()

# For each patient, generate a random name based on gender and update the record
for pid, sex in patients:
    # Determine the gender and generate a name
    if sex == 'Male':
        fname = fake.first_name_male()
        lname = fake.last_name_male()
    elif sex == 'Female':
        fname = fake.first_name_female()
        lname = fake.last_name_female()
    else:
        # If gender is unknown or other, randomly choose
        fname = fake.first_name()
        lname = fake.last_name()

    # Execute the update statement
    cursor.execute(update_sql, (fname, lname, pid))

# Commit changes and close the connection
conn.commit()
cursor.close()
conn.close()

