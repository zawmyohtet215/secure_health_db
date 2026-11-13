-- =====================================================================
-- Part 3, Task 3: Audit logging for SecureHealthDB
--   A) Enable MySQL general query log (tracks access to sensitive data)
--   B) Triggers that log changes to sensitive patient fields
-- Run as root (needs SYSTEM_VARIABLES_ADMIN / SUPER for the log settings).
-- Screenshot target: Part3_task3.png
-- =====================================================================

USE SecureHealthDB;

-- ---------------------------------------------------------------------
-- A) GENERAL QUERY LOG
-- ---------------------------------------------------------------------
SET GLOBAL log_output  = 'TABLE';   -- write to mysql.general_log table
SET GLOBAL general_log = 'ON';

SHOW VARIABLES LIKE 'general_log';
SHOW VARIABLES LIKE 'log_output';

-- ---------------------------------------------------------------------
-- B) AUDIT TABLE + TRIGGERS ON patients
-- Old/new values are stored in their ENCRYPTED form (never plain text).
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS patient_audit_log (
  audit_id      BIGINT AUTO_INCREMENT PRIMARY KEY,
  patient_id    INT          NOT NULL,
  action        VARCHAR(10)  NOT NULL,         -- INSERT / UPDATE / DELETE
  changed_field VARCHAR(50)  NOT NULL,
  old_value     VARBINARY(255),
  new_value     VARBINARY(255),
  changed_by    VARCHAR(100) NOT NULL,         -- MySQL user who made the change
  changed_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

DROP TRIGGER IF EXISTS trg_patients_after_insert;
DROP TRIGGER IF EXISTS trg_patients_after_update;
DROP TRIGGER IF EXISTS trg_patients_after_delete;

DELIMITER $$

CREATE TRIGGER trg_patients_after_insert
AFTER INSERT ON patients
FOR EACH ROW
BEGIN
  INSERT INTO patient_audit_log (patient_id, action, changed_field, old_value, new_value, changed_by)
  VALUES (NEW.id, 'INSERT', 'medical_record',   NULL, NEW.medical_record,   USER()),
         (NEW.id, 'INSERT', 'insurance_number', NULL, NEW.insurance_number, USER());
END$$

CREATE TRIGGER trg_patients_after_update
AFTER UPDATE ON patients
FOR EACH ROW
BEGIN
  IF NOT (OLD.medical_record <=> NEW.medical_record) THEN
    INSERT INTO patient_audit_log (patient_id, action, changed_field, old_value, new_value, changed_by)
    VALUES (NEW.id, 'UPDATE', 'medical_record', OLD.medical_record, NEW.medical_record, USER());
  END IF;

  IF NOT (OLD.insurance_number <=> NEW.insurance_number) THEN
    INSERT INTO patient_audit_log (patient_id, action, changed_field, old_value, new_value, changed_by)
    VALUES (NEW.id, 'UPDATE', 'insurance_number', OLD.insurance_number, NEW.insurance_number, USER());
  END IF;
END$$

CREATE TRIGGER trg_patients_after_delete
AFTER DELETE ON patients
FOR EACH ROW
BEGIN
  INSERT INTO patient_audit_log (patient_id, action, changed_field, old_value, new_value, changed_by)
  VALUES (OLD.id, 'DELETE', 'medical_record',   OLD.medical_record,   NULL, USER()),
         (OLD.id, 'DELETE', 'insurance_number', OLD.insurance_number, NULL, USER());
END$$

DELIMITER ;

SHOW TRIGGERS LIKE 'patients';

-- ---------------------------------------------------------------------
-- TEST: make a change, then view both logs
-- ---------------------------------------------------------------------
SET @aes_key = 'HospitalSecretKey#2026';

UPDATE patients
SET medical_record = AES_ENCRYPT('Hypertension; BP now stable', @aes_key)
WHERE id = 1;

-- 1) Trigger audit trail (values stay encrypted)
SELECT audit_id, patient_id, action, changed_field,
       HEX(old_value) AS old_encrypted,
       HEX(new_value) AS new_encrypted,
       changed_by, changed_at
FROM patient_audit_log
ORDER BY audit_id DESC;

-- 2) General query log: who touched the patients table
SELECT event_time, user_host,
       CONVERT(argument USING utf8mb4) AS statement
FROM mysql.general_log
WHERE CONVERT(argument USING utf8mb4) LIKE '%patients%'
  AND command_type = 'Query'
ORDER BY event_time DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- IMPORTANT: the general log stores full SQL text, including the AES key
-- used above. Turn it off after your audit window and purge it.
-- ---------------------------------------------------------------------
-- SET GLOBAL general_log = 'OFF';
-- TRUNCATE TABLE mysql.general_log;
