CREATE OR REPLACE FUNCTION
  valid_deptid (depID Departments.Department_ID%TYPE)
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
/


CREATE OR REPLACE PROCEDURE
  add_employee (
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
/