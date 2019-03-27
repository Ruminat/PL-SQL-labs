CREATE OR REPLACE PACKAGE job_pkg IS
  PROCEDURE add_job (id Jobs.Job_ID%TYPE, job_title Jobs.Job_Title%TYPE);
  PROCEDURE upd_job (id Jobs.Job_ID%TYPE, jobTitle Jobs.Job_Title%TYPE);
  PROCEDURE del_job (id Jobs.Job_ID%TYPE);
  FUNCTION  get_job (id Jobs.Job_ID%TYPE) RETURN Jobs.Job_Title%TYPE;
END job_pkg;