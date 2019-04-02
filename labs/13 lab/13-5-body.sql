CREATE OR REPLACE PACKAGE BODY emp_pkg IS

  TYPE boolean_tab_type IS TABLE OF BOOLEAN INDEX BY BINARY_INTEGER;
  valid_departments boolean_tab_type;

  FUNCTION valid_deptid (depID Departments.Department_ID%TYPE) RETURN BOOLEAN;

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

  PROCEDURE add_employee (
      firstName Employees.First_Name%TYPE
    ,  lastName Employees.Last_Name%TYPE
    ,     depID Employees.Department_ID%TYPE
    ) IS
    email Employees.Email%TYPE := UPPER(SUBSTR(firstName, 1, 1)) || UPPER(SUBSTR(lastName, 1, 7));
  BEGIN
    add_employee(firstName, lastName, mail => email, depID => depID);
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

  FUNCTION get_employee (p_emp_id Employees.Employee_ID%TYPE)
  RETURN Employees%ROWTYPE IS
    emp Employees%ROWTYPE;
  BEGIN
    SELECT *
    INTO   emp
    FROM Employees
    WHERE Employee_ID = p_emp_id;

    RETURN emp;
  END;

  FUNCTION get_employee (p_family_name Employees.Last_Name%TYPE)
  RETURN Employees%ROWTYPE IS
    emp Employees%ROWTYPE;
  BEGIN
    SELECT *
    INTO   emp
    FROM Employees
    WHERE Last_Name = p_family_name;

    RETURN emp;
  END;

  PROCEDURE init_departments IS BEGIN
    FOR row IN (SELECT Department_ID FROM Departments) LOOP
      valid_departments(row.Department_ID) := TRUE;
    END LOOP;
  END;

  PROCEDURE print_employee (emp Employees%ROWTYPE) IS BEGIN
    DBMS_OUTPUT.PUT_LINE(
         'Emp#' || emp.Employee_ID || ': '
      || emp.First_Name || ' ' || emp.Last_Name
      || ', depID is '  || emp.Department_ID
      || ', job is '    || emp.Job_ID
      || ', salary is ' || emp.Salary || '.'
    );
  END;


  /*
    --- PRIVATE ---
  */
  FUNCTION valid_deptid (depID Departments.Department_ID%TYPE)
  RETURN BOOLEAN IS 
  BEGIN
    IF valid_departments(depID) THEN RETURN TRUE;
    ELSE RETURN FALSE; END IF;
  EXCEPTION
    WHEN OTHERS THEN RETURN FALSE;
  END valid_deptid;

BEGIN
  init_departments();
END emp_pkg;
/