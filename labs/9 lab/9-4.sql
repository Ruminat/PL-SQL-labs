CREATE OR REPLACE PROCEDURE
  get_employee (
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