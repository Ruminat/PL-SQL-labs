TRUNCATE TABLE Messages;

DEFINE sal = 6000

DECLARE
  ename Employees.Last_Name%TYPE;
  emp_sal Employees.Salary%TYPE := &sal;
BEGIN
  SELECT Last_Name
  INTO ename
  FROM Employees
  WHERE Salary = emp_sal;
  
  INSERT INTO Messages (Results)
  VALUES (ename || ': ' || emp_sal || '$');
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    INSERT INTO Messages (Results)
    VALUES ('No employee with a salary of ' || emp_sal);
  WHEN TOO_MANY_ROWS THEN
    INSERT INTO Messages (Results)
    VALUES ('More than one employee with a salary of ' || emp_sal);
END;
/

COMMIT;

SELECT *
FROM Messages;