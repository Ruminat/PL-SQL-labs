CREATE OR REPLACE PACKAGE BODY emp_pkg IS

  /*
    --- PRIVATE ---
  */
  FUNCTION valid_deptid (depID Departments.Department_ID%TYPE)
  RETURN BOOLEAN IS 
  BEGIN
    FOR i IN (
        SELECT 'Exists' FROM dual
        WHERE EXISTS (
          SELECT Department_ID
          FROM Departments
          WHERE Department_ID = depID
        )
      )
    LOOP
      RETURN TRUE;
    END LOOP;
    RETURN FALSE;
  END valid_deptid;


  /*
    --- PUBLIC ---
  */
  PROCEDURE add_employee (
      firstName Employees.First_Name%TYPE
    ,  lastName Employees.Last_Name%TYPE
    ,      mail Employees.Email%TYPE
    ,       job Employees.Job_ID%TYPE          := 'SA_REP'
    ,       mgr Employees.Manager_ID%TYPE      := 145
    ,       sal Employees.Salary%TYPE          := 1000
    ,      comm Employees.Commission_PCT%TYPE  := 0
    ,     depID Employees.Department_ID%TYPE   := 30
    ) IS
  BEGIN
    IF valid_deptid(depID) THEN
      INSERT INTO Employees (
        Employee_ID
      , First_Name
      , Last_Name
      , Email
      , Hire_Date
      , Job_ID
      , Manager_ID
      , Salary
      , Commission_PCT
      , Department_ID
      )
      VALUES (
        Employees_Seq.NEXTVAL -- Employee_ID
      , firstName
      , lastName
      , mail
      , TRUNC(SYSDATE) -- Hire_Date
      , job
      , mgr
      , sal
      , comm
      , depID
      );
    ELSE
      DBMS_OUTPUT.PUT_LINE(
        'Error: cannot add an employee to a nonexistent department #' || depID || '.'
      );
    END IF;
  END add_employee;


  PROCEDURE get_employee (
      id            Employees.Employee_ID%TYPE,
      jobID     OUT Employees.Job_ID%TYPE,
      empSalary OUT Employees.Salary%TYPE
    ) IS
  BEGIN
    SELECT Job_ID, Salary
    INTO   jobID,  empSalary
    FROM Employees
    WHERE Employee_ID = id;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('get_employee error:');
      DBMS_OUTPUT.PUT_LINE(
           '  could not get Employee information from'
        || ' get_employee(' || id || ', jobID, empSalary).'
      );
      DBMS_OUTPUT.PUT_LINE('  There is no employee with ID ' || id || '.');
  END get_employee;

END emp_pkg;