CREATE OR REPLACE TRIGGER upd_minsalary_trg
FOR UPDATE OF Min_Salary ON Jobs
COMPOUND TRIGGER

    TYPE minSalaryMap IS TABLE OF Jobs.min_salary%TYPE INDEX BY Jobs.job_id%TYPE;
    jobsTab minSalaryMap;
    jobID   Jobs.job_id%TYPE;

  AFTER EACH ROW IS
  BEGIN
    IF :OLD.Min_Salary != :NEW.Min_Salary THEN
      jobsTab(:NEW.job_id) := :NEW.min_salary;
    END IF;
  END AFTER EACH ROW;

  AFTER STATEMENT IS
  BEGIN
      jobID := jobsTab.FIRST;
      WHILE jobID IS NOT NULL LOOP
        emp_pkg.set_salary(jobID, jobsTab(jobID));
        jobID := jobsTab.NEXT(jobID);
      END LOOP;
  END AFTER STATEMENT;
END upd_minsalary_trg;
/