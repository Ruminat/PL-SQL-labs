CREATE OR REPLACE FUNCTION
  get_job (id Jobs.Job_ID%TYPE)
RETURN Jobs.Job_Title%TYPE IS
  title Jobs.Job_Title%TYPE;
BEGIN
  SELECT Job_Title
  INTO   title
  FROM Jobs
  WHERE Job_ID = id;

  RETURN title;
END get_job;