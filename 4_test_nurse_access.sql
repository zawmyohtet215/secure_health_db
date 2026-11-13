-- Scenario 2: Nurse's Access
SELECT * FROM patients_nonsensitive;   -- works
SELECT * FROM patients;                -- ERROR 1142: SELECT command denied
-- Expected: id, name, dob only; direct table access denied.