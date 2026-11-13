-- Scenario 1: Doctor's Access

SET @aes_key = 'HospitalSecretKey#2026';

SELECT id, name,
       CAST(AES_DECRYPT(medical_record, @aes_key)   AS CHAR) AS medical_record,
       CAST(AES_DECRYPT(insurance_number, @aes_key) AS CHAR) AS insurance_number
FROM patients;
-- Expected: readable medical records and insurance numbers.

