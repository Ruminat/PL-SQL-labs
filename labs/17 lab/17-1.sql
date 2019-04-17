CREATE OR REPLACE PROCEDURE
  check_salary (jobID Employees.Job_ID%TYPE, sal Employees.Salary%TYPE) IS
  minSal Jobs.Min_Salary%TYPE;
  maxSal Jobs.Max_Salary%TYPE;
BEGIN
  SELECT Min_Salary, Max_Salary
  INTO   minSal,     maxSal
  FROM Jobs
  WHERE Job_ID = jobID;

  IF sal NOT BETWEEN minSal AND maxSal THEN
    RAISE_APPLICATION_ERROR(
      -20001,
        'Invalid salary '|| sal ||' for this job. Salaries must be between '
      || minSal ||' and '|| maxSal
    );
  END IF;
END check_salary;
/

CREATE OR REPLACE TRIGGER check_salary_trg
BEFORE INSERT OR UPDATE OF Salary, Job_ID ON Employees
FOR EACH ROW
BEGIN
  check_salary(:NEW.Job_ID, :NEW.Salary);
END;
/