CREATE OR REPLACE PROCEDURE
  del_job (id Jobs.Job_ID%TYPE) IS
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