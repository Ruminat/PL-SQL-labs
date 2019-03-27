VARIABLE b_title VARCHAR2;
DECLARE
  id Jobs.Job_ID%TYPE := 'SA_REP';
BEGIN
  :b_title := get_job(id);
  DBMS_OUTPUT.PUT_LINE('get_job(''' || id || ''') = ' || :b_title);
END;