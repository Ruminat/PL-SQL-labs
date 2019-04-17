CREATE OR REPLACE PROCEDURE
  schedule_report (interval SIMPLE_INTEGER, duration SIMPLE_INTEGER := 10) IS
      theDate VARCHAR(64)   := TO_CHAR(SYSDATE, 'DD.MM.YYYY HH24-MI-SS');
     fileName VARCHAR2(256) := 'sal_rpt_vlafur1_'|| theDate ||'.txt';
  plsql_block VARCHAR2(200) := 'BEGIN employee_report(''STUD_PLSQL'', '''|| fileName ||'''); END;';
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
            JOB_NAME => 'empsal_report'
   ,        JOB_TYPE => 'PLSQL_BLOCK'
   ,      JOB_ACTION => plsql_block
   ,      START_DATE => SYSTIMESTAMP
   ,        END_DATE => (SYSTIMESTAMP + duration / (60 * 24))
   , REPEAT_INTERVAL => 'FREQUENCY=MINUTELY; INTERVAL='|| interval
   ,         ENABLED => TRUE
  );
END schedule_report;
/

BEGIN
  schedule_report(2, 6);
END;
/

SELECT Job_Name, Job_Type
FROM USER_SCHEDULER_JOBS;