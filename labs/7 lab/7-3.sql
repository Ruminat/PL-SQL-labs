DECLARE
  -- Department cursor
  CURSOR dept_cursor IS
    SELECT Department_ID, Department_Name
    FROM Departments
    WHERE Department_ID < 100;

  -- Employee cursor
  CURSOR emp_cursor (depID Departments.Department_ID%TYPE) IS
    SELECT Last_Name, Job_ID, Hire_Date, Salary
    FROM Employees
    WHERE Employee_ID < 120 AND Department_ID = depID;

  -- Department variables
  depID   Departments.Department_ID%TYPE;
  depName Departments.Department_Name%TYPE;

  -- Employee variables
  lastName Employees.Last_Name%TYPE;
  jobID    Employees.Job_ID%TYPE;
  hireDate Employees.Hire_Date%TYPE;
  sal      Employees.Salary%TYPE;
BEGIN
  OPEN dept_cursor;
  LOOP -- Department
    FETCH dept_cursor INTO depID, depName;
    EXIT WHEN dept_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Department Number: ' || depID || ' Department Name: ' || depName);
    OPEN emp_cursor (depID);
    LOOP -- Employee
      FETCH emp_cursor INTO lastName, jobID, hireDate, sal;
      EXIT WHEN emp_cursor%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(
           lastName || ' '
        || jobID    || ' '
        || TO_CHAR(hireDate, 'dd-MON-rr', 'NLS_DATE_LANGUAGE = English') || ' '
        || sal
      );
    END LOOP; -- Employee
    CLOSE emp_cursor;
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------');
  END LOOP; -- Department
  CLOSE dept_cursor;
END;