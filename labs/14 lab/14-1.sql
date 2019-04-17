CREATE OR REPLACE PROCEDURE
  employee_report (dir VARCHAR2, fileName VARCHAR2) IS
  file UTL_FILE.FILE_TYPE := UTL_FILE.FOPEN(dir, fileName, 'W');
BEGIN
  UTL_FILE.PUT_LINE(
    file,
       '--- Отчёт. Влад Фурман, 33536/2 ['
    || TO_CHAR(SYSDATE, 'DD.MM.YYYY HH24:MI:SS')
    ||'] ---'
  );
  FOR row IN (
    SELECT *
    FROM (
      SELECT
        Employee_ID, First_Name, Last_Name, Department_ID, Salary,
        AVG(Salary) OVER (PARTITION BY Department_ID) AS Average
      FROM Employees
    )
    WHERE Salary > Average
    ORDER BY Employee_ID
  )
  LOOP
    UTL_FILE.PUT_LINE(
      file,
         'Emp #' || row.Employee_ID || ': '
      || row.First_Name || ' ' || row.Last_Name || ', '
      || 'dep #' || row.Department_ID || ', '
      || 'salary is ' || row.Salary
    );
  END LOOP;

  UTL_FILE.FCLOSE(file);
-- EXCEPTION
END employee_report;
/


DECLARE
  dir           VARCHAR(64)   := 'STUD_PLSQL';
  theDate       VARCHAR(64)   := TO_CHAR(SYSDATE, 'DD.MM.YYYY HH24-MI-SS');
  fileName      VARCHAR2(256) := 'sal_rpt_vlafur1_'|| theDate ||'.txt';
  currentString VARCHAR2(1024);
  file UTL_FILE.FILE_TYPE;
BEGIN
  employee_report (dir, fileName);
  file := UTL_FILE.FOPEN(dir, fileName, 'R');

  DBMS_OUTPUT.PUT_LINE('Содержимое файла '|| fileName ||':');

  LOOP
    BEGIN
      UTL_FILE.GET_LINE(file, currentString);
      DBMS_OUTPUT.PUT_LINE(currentString);
    EXCEPTION WHEN NO_DATA_FOUND THEN EXIT;
    END;
  END LOOP;

  UTL_FILE.FCLOSE(file);
END;
/