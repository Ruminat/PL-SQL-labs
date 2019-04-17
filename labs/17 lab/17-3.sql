CREATE OR REPLACE TRIGGER check_salary_trg
BEFORE INSERT OR UPDATE OF Salary, Job_ID ON Employees
FOR EACH ROW
WHEN (
     OLD.Job_ID IS NULL       OR OLD.Salary IS NULL
  OR OLD.Job_ID != NEW.Job_ID OR OLD.Salary != NEW.Salary
)
BEGIN
  check_salary(:NEW.Job_ID, :NEW.Salary);
END;
/