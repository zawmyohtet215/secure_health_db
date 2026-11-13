-- Task 1 - Insert sample data into "roles" table
INSERT INTO roles (role_name) VALUES ('Doctor'), ('Nurse'), ('Admin');
 
SELECT * FROM roles;



-- TASK 2: AES encryption on sensitive fields
SET @aes_key = 'HospitalSecretKey#2026';
 
INSERT INTO patients (name, dob, medical_record, insurance_number) VALUES
 ('John Smith',   '1985-04-12',
   AES_ENCRYPT('Hypertension; on Lisinopril', @aes_key),
   AES_ENCRYPT('INS-100234', @aes_key)),
 ('Mary Johnson', '1990-09-30',
   AES_ENCRYPT('Type 2 Diabetes; on Metformin', @aes_key),
   AES_ENCRYPT('INS-200567', @aes_key));
 
-- Stored form is unreadable:
SELECT id, name,
       HEX(medical_record)   AS encrypted_medical_record,
       HEX(insurance_number) AS encrypted_insurance_number
FROM patients;
 
-- Decrypts correctly with the key:
SELECT id, name,
       CAST(AES_DECRYPT(medical_record, @aes_key)   AS CHAR) AS medical_record,
       CAST(AES_DECRYPT(insurance_number, @aes_key) AS CHAR) AS insurance_number
FROM patients;



-- TASK 3: Employees + role assignment
-- Passwords are stored AES-encrypted in the VARBINARY column.
INSERT INTO employees (name, role_id, email, password)
VALUES
 ('Dr. Alice Brown',  (SELECT id FROM roles WHERE role_name='Doctor'),
   'alice.brown@securehealth.com', AES_ENCRYPT('Doctor@123', @aes_key)),
 ('Nurse Bob Wilson', (SELECT id FROM roles WHERE role_name='Nurse'),
   'bob.wilson@securehealth.com',  AES_ENCRYPT('Nurse@123',  @aes_key)),
 ('Carol Admin',      (SELECT id FROM roles WHERE role_name='Admin'),
   'carol.admin@securehealth.com', AES_ENCRYPT('Admin@123',  @aes_key));
 
INSERT INTO employee_roles (employee_id, role_id)
SELECT id, role_id FROM employees;
 
SELECT e.id, e.name, e.email, r.role_name, HEX(e.password) AS encrypted_password
FROM employees e
JOIN employee_roles er ON e.id = er.employee_id
JOIN roles r           ON er.role_id = r.id;



-- TASK 4: RBAC - one MySQL user per role
-- Non-sensitive view for nurses (no medical_record / insurance_number)
CREATE OR REPLACE VIEW patients_nonsensitive AS
SELECT id, name, dob FROM patients;
 
CREATE USER IF NOT EXISTS 'doctor_user'@'%' IDENTIFIED BY 'Doctor@123';
CREATE USER IF NOT EXISTS 'nurse_user'@'%'  IDENTIFIED BY 'Nurse@123';
CREATE USER IF NOT EXISTS 'admin_user'@'%'  IDENTIFIED BY 'Admin@123';
 
-- Doctor: full access to patients (can decrypt using the key)
GRANT SELECT, INSERT, UPDATE ON SecureHealthDB.patients TO 'doctor_user'@'%';
 
-- Nurse: only the non-sensitive view
GRANT SELECT ON SecureHealthDB.patients_nonsensitive TO 'nurse_user'@'%';
 
-- Admin: manage employees and roles, no patient data
GRANT SELECT, INSERT, UPDATE, DELETE ON SecureHealthDB.employees      TO 'admin_user'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON SecureHealthDB.employee_roles TO 'admin_user'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON SecureHealthDB.roles          TO 'admin_user'@'%';
 
FLUSH PRIVILEGES;
 
SHOW GRANTS FOR 'doctor_user'@'%';
SHOW GRANTS FOR 'nurse_user'@'%';
SHOW GRANTS FOR 'admin_user'@'%';