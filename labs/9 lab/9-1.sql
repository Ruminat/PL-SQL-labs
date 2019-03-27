CREATE OR REPLACE PROCEDURE
  add_job (id Jobs.Job_ID%TYPE, job_title Jobs.Job_Title%TYPE) IS
BEGIN
  INSERT INTO Jobs (Job_ID, Job_Title)
  VALUES           (id,     job_title);
END add_job;