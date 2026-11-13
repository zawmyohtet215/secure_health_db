-- Scenario 3: ADMIN
SELECT e.name, r.role_name
FROM employees e
JOIN employee_roles er ON e.id = er.employee_id
JOIN roles r           ON er.role_id = r.id;   -- works

SELECT * FROM patients;                         -- ERROR 1142: denied
-- Expected: employee/role list shown; patient data denied.