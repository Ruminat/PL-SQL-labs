CREATE OR REPLACE PACKAGE jobs_pkg IS
  PROCEDURE initialize;
  FUNCTION  get_minSalary (jobID VARCHAR2) RETURN NUMBER;
  FUNCTION  get_maxSalary (jobID VARCHAR2) RETURN NUMBER;
  PROCEDURE set_minSalary (jobID VARCHAR2, min_salary NUMBER);
  PROCEDURE set_maxSalary (jobID VARCHAR2, max_salary NUMBER);
END jobs_pkg;
/