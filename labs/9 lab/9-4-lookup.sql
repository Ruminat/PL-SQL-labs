DECLARE
  jobID     Employees.Job_ID%TYPE;
  empSalary Employees.Salary%TYPE;
BEGIN
  get_employee(120, jobID, empSalary);
  DBMS_OUTPUT.PUT_LINE(
       'Employee #120: Job_ID = ' || NVL(jobID, '(null)')
    || ', Salary = ' || NVL(TO_CHAR(empSalary), '(null)') || '.'
  );
  get_employee(300, jobID, empSalary);
  DBMS_OUTPUT.PUT_LINE(
       'Employee #300: Job_ID = ' || NVL(jobID, '(null)')
    || ', Salary = ' || NVL(TO_CHAR(empSalary), '(null)') || '.'
  );
END;