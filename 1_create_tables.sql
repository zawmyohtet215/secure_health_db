USE Securehealthdb;

CREATE TABLE employees (
id int AUTO_INCREMENT PRIMARY KEY,
name varchar(100) NOT NULL,
role_id int, -- Links to roles_table for role-based access
email varchar(100) NOT NULL,
password varbinary(255) -- Encrypted password FOR secure login
);

CREATE TABLE patients (
id int AUTO_INCREMENT PRIMARY KEY,
name varchar(100) NOT NULL,
dob date, -- Date of Birth
medical_record varbinary(255), -- Encrypted field for medical history
insurance_number varbinary(255)-- Encrypted field for insurance details
);

CREATE TABLE roles (
id int AUTO_INCREMENT PRIMARY KEY,
role_name varchar(50) NOT NULL 
);

CREATE TABLE employee_roles(
employee_id int,
role_id int,
FOREIGN KEY (employee_id) REFERENCES employees(id),
FOREIGN KEY (role_id) REFERENCES roles(id)
);