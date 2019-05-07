CREATE OR REPLACE PACKAGE BODY jobs_pkg IS
  TYPE jobs_tab_type IS TABLE OF Jobs%ROWTYPE INDEX BY Jobs.Job_ID%TYPE;
  jobsTab jobs_tab_type;

  PROCEDURE initialize IS
  BEGIN
    FOR job IN (SELECT * FROM Jobs) LOOP
      jobsTab(job.Job_ID) := job;
    END LOOP;
  END;
  
  FUNCTION  get_minSalary (jobID VARCHAR2) RETURN NUMBER IS
  BEGIN
    RETURN jobsTab(jobID).Min_Salary;
  END;
  
  FUNCTION  get_maxSalary (jobID VARCHAR2) RETURN NUMBER IS
  BEGIN
    RETURN jobsTab(jobID).Max_Salary;
  END;
  
  PROCEDURE set_minSalary (jobID VARCHAR2, min_salary NUMBER) IS
  BEGIN
    jobsTab(jobID).Min_Salary := min_salary;
  END;
  
  PROCEDURE set_maxSalary (jobID VARCHAR2, max_salary NUMBER) IS
  BEGIN
    jobsTab(jobID).Max_Salary := max_salary;
  END;

END jobs_pkg;
/