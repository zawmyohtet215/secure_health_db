# SecureHealthDB

A MySQL database project for a fictional healthcare company, **SecureHealth Inc.**, showing encryption, role-based access control (RBAC), data governance, compliance and audit logging.

> **Demo project.** All names, passwords and the AES key in these scripts are sample values for learning. Never reuse them, and never commit real keys or passwords.

## What it covers

| Part | Topic | Files |
|------|-------|-------|
| 1 | Database, AES-encrypted fields, roles, employees, RBAC users, access tests | `1_create_tables.sql`, `2_secure_tables.sql`, `3_test_doctor_access.sql`, `4_test_nurse_access.sql`, `5_test_admin_access.sql` |
| 2 | ERD (3NF), governance principles, roles and responsibilities | `Part2_task2a.doc`, `Part2_task2b.doc`, ERD image in `output_images/` |
| 3 | Risk management plan, GDPR/HIPAA compliance, audit logging with triggers | `Part3_task1.doc`, `Part3_task2.doc`, `Part3_Task3_audit.sql` |

## Design highlights

- **Encryption:** `medical_record`, `insurance_number` and employee passwords are stored as `VARBINARY` using `AES_ENCRYPT`.
- **RBAC:** separate MySQL users for Doctor, Nurse and Admin.
  - Doctors can read and decrypt patient data.
  - Nurses see only a non-sensitive view (`patients_nonsensitive`).
  - Admins manage employees and roles but cannot read patient records.
- **Audit logging:** triggers write every change to sensitive patient fields into `patient_audit_log`, and the MySQL general query log tracks access.

## How to run

1. Install MySQL 8 and a client (MySQL Workbench, DBeaver or the `mysql` CLI).
2. Run the scripts in numeric order, then `Part3_Task3_audit.sql`.
3. Log in as each role user (`doctor_user`, `nurse_user`, `admin_user`) to repeat the access tests.

In DBeaver, run each `CREATE TRIGGER ... END;` block by selecting it and pressing Ctrl+Enter (DBeaver does not use `DELIMITER`).

## Security notes

- The general query log records full SQL text, including encryption keys. Enable it only for short audit windows, then run `SET GLOBAL general_log = 'OFF';` and truncate `mysql.general_log`.
- In a real system, keep the encryption key in a key vault or environment secret, not in SQL files.
