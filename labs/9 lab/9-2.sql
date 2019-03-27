CREATE OR REPLACE PROCEDURE
  upd_job (id Jobs.Job_ID%TYPE, jobTitle Jobs.Job_Title%TYPE) IS
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