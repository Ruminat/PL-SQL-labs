DEFINE p_deptno = &Enter_The_Department

DECLARE
  deptno NUMBER := &p_deptno;
  CURSOR emp_cursor IS
    SELECT Last_Name, Salary, Manager_ID
    FROM Employees
    WHERE Department_ID = deptno;
BEGIN
  FOR emp IN emp_cursor LOOP
    IF emp.Salary < 5000 AND emp.Manager_ID IN (101, 124) THEN
      DBMS_OUTPUT.PUT_LINE(emp.Last_Name || ' Due for a raise');
    ELSE
      DBMS_OUTPUT.PUT_LINE(emp.Last_Name || ' Not due for a raise');
    END IF;
  END LOOP;
END;