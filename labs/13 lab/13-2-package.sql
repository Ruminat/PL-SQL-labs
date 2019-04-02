CREATE OR REPLACE PACKAGE emp_pkg IS
  PROCEDURE add_employee (
    firstName Employees.First_Name%TYPE
  ,  lastName Employees.Last_Name%TYPE
  ,      mail Employees.Email%TYPE
  ,       job Employees.Job_ID%TYPE          := 'SA_REP'
  ,       mgr Employees.Manager_ID%TYPE      := 145
  ,       sal Employees.Salary%TYPE          := 1000
  ,      comm Employees.Commission_PCT%TYPE  := 0
  ,     depID Employees.Department_ID%TYPE   := 30
  );

  PROCEDURE add_employee (
    firstName Employees.First_Name%TYPE
  ,  lastName Employees.Last_Name%TYPE
  ,     depID Employees.Department_ID%TYPE
  );

  PROCEDURE get_employee (
    id            Employees.Employee_ID%TYPE
  , jobID     OUT Employees.Job_ID%TYPE
  , empSalary OUT Employees.Salary%TYPE
  );

  FUNCTION get_employee (p_emp_id Employees.Employee_ID%TYPE)
  RETURN Employees%ROWTYPE;

  FUNCTION get_employee (p_family_name Employees.Last_Name%TYPE)
  RETURN Employees%ROWTYPE;

  PROCEDURE print_employee (emp Employees%ROWTYPE);
END emp_pkg;