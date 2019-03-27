CREATE OR REPLACE PACKAGE BODY job_pkg IS

  PROCEDURE add_job (id Jobs.Job_ID%TYPE, job_title Jobs.Job_Title%TYPE) IS
  BEGIN
    INSERT INTO Jobs (Job_ID, Job_Title)
    VALUES           (id,     job_title);
  END add_job;


  PROCEDURE upd_job (id Jobs.Job_ID%TYPE, jobTitle Jobs.Job_Title%TYPE) IS
  BEGIN
    UPDATE Jobs
    SET Job_Title = jobTitle
    WHERE Job_ID = id;
    
    IF NOT SQL%FOUND THEN
      DBMS_OUTPUT.PUT_LINE('upd_job error:');
      DBMS_OUTPUT.PUT_LINE(
           '  there were no modifications applied for'
        || ' upd_job(''' || id || ''', ''' || jobTitle || ''').'
      );
      DBMS_OUTPUT.PUT_LINE('  There is no job with ID ''' || id || '''.');
    END IF;
  END upd_job;


  PROCEDURE del_job (id Jobs.Job_ID%TYPE) IS
  BEGIN
    DELETE FROM Jobs WHERE Job_ID = id;
    
    IF NOT SQL%FOUND THEN
      DBMS_OUTPUT.PUT_LINE('del_job error:');
      DBMS_OUTPUT.PUT_LINE(
           '  there were no records deleted by'
        || ' del_job(''' || id || ''').'
      );
      DBMS_OUTPUT.PUT_LINE('  There is no job with ID ''' || id || '''.');
    END IF;
  END del_job;


  FUNCTION get_job (id Jobs.Job_ID%TYPE)
  RETURN Jobs.Job_Title%TYPE IS
    title Jobs.Job_Title%TYPE;
  BEGIN
    SELECT Job_Title
    INTO   title
    FROM Jobs
    WHERE Job_ID = id;

    RETURN title;
  END get_job;

END job_pkg;