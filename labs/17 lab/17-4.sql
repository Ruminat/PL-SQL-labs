CREATE OR REPLACE TRIGGER delete_emp_trg
BEFORE DELETE ON Employees
BEGIN
  IF TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')) NOT BETWEEN 8 AND 17 THEN
    RAISE_APPLICATION_ERROR(
      -20001,
      'You can delete an employee only during normal business hours (08:00–18:00)'
    );      
  END IF;
END;
/