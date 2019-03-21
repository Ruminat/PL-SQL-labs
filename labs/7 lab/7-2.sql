DEFINE p_deptno = &Enter_The_Department

DECLARE
  deptno NUMBER := &p_deptno;
  depOut   VARCHAR2(10);
  raiseOut VARCHAR2(10);
  CURSOR emp_cursor IS
    SELECT Last_Name, Salary, Manager_ID
    FROM Employees
    WHERE Department_ID = deptno;
BEGIN
  FOR emp IN emp_cursor LOOP
    depOut :=
      CASE
        WHEN emp_cursor%ROWCOUNT = 1
        THEN RPAD(deptno, LENGTH(deptno) + 3, ' ')
        ELSE RPAD(' ',    LENGTH(deptno) + 3, ' ')
      END;
    raiseOut :=
      CASE
        WHEN emp.Salary < 5000 AND emp.Manager_ID IN (101, 124)
        THEN ' Due'
        ELSE ' Not due'
      END;
    DBMS_OUTPUT.PUT_LINE(depOut || emp.Last_Name || raiseOut || ' for a raise');
  END LOOP;
END;