CREATE OR REPLACE TRIGGER employee_initJobs_trg
BEFORE INSERT OR UPDATE ON Employees
BEGIN
  jobs_pkg.initialize;
END;
/