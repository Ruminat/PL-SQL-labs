CREATE OR REPLACE TRIGGER upd_minsalary_trg
AFTER UPDATE OF Min_Salary ON Jobs
FOR EACH ROW
WHEN (OLD.Min_Salary != NEW.Min_Salary)
BEGIN
  emp_pkg.set_salary(:NEW.Job_ID, :NEW.Min_Salary);
END;
/