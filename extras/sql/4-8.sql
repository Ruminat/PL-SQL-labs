CREATE OR REPLACE PACKAGE generate IS
  PROCEDURE rows (n SIMPLE_INTEGER := 0);
END;
/

CREATE OR REPLACE PACKAGE BODY generate IS
  TYPE rowsT IS TABLE OF SIMPLE_INTEGER;

  PROCEDURE rows (n SIMPLE_INTEGER := 0) IS
    rowsTable rowsT := rowsT();
    maxValue  SIMPLE_INTEGER := 1;
    rowsCount SIMPLE_INTEGER := 0;
  BEGIN
    rowsTable.EXTEND(n);
    <<mainLoop>> WHILE TRUE LOOP
      FOR i IN 1..maxValue LOOP
        EXIT mainLoop WHEN rowsCount >= n;
        rowsCount := rowsCount + 1;
        rowsTable(rowsCount) := i;
      END LOOP;
      maxValue := maxValue + 1;
    END LOOP mainLoop;

    FORALL i IN 1..n
      SAVE EXCEPTIONS
      INSERT INTO Duplicates VALUES (rowsTable(i));
  END;
END;
/

CREATE OR REPLACE PROCEDURE distinctDSQL (
    tableName VARCHAR2, userName VARCHAR2 := USER
  ) IS
  fullName VARCHAR2(255) := userName ||'.'|| tableName;
BEGIN
  EXECUTE IMMEDIATE
       'DECLARE'
    || '  TYPE tableRowsT IS TABLE OF '|| fullName ||'%ROWTYPE;'
    || '  tableRows tableRowsT;'
    || 'BEGIN'
    || '  SELECT DISTINCT * BULK COLLECT INTO tableRows FROM '|| fullName ||';'
    || '  DELETE FROM '|| fullName ||';'
    || '  FORALL i IN tableRows.FIRST..tableRows.LAST'
    || '    INSERT INTO '|| fullName ||' VALUES tableRows(i);'
    || 'END;';
END;
/

CREATE OR REPLACE PROCEDURE distinctDBMS_SQL (
    tableName VARCHAR2, userName VARCHAR2 := USER
  ) IS
  fullName VARCHAR2(255) := userName ||'.'|| tableName;
  cursorID PLS_INTEGER := DBMS_SQL.OPEN_CURSOR;
  rowsAdded PLS_INTEGER;
BEGIN
  DBMS_SQL.PARSE(
     cursorID
   ,    'DECLARE'
     || '  TYPE tableRowsT IS TABLE OF '|| fullName ||'%ROWTYPE;'
     || '  tableRows tableRowsT;'
     || 'BEGIN'
     || '  SELECT DISTINCT * BULK COLLECT INTO tableRows FROM '|| fullName ||';'
     || '  DELETE FROM '|| fullName ||';'
     || '  FORALL i IN tableRows.FIRST..tableRows.LAST'
     || '    INSERT INTO '|| fullName ||' VALUES tableRows(i);'
     || 'END;'
   , DBMS_SQL.NATIVE
  );
  rowsAdded := DBMS_SQL.EXECUTE(cursorID);
  DBMS_SQL.CLOSE_CURSOR(cursorID);
END;
/

SELECT COUNT(*) FROM TestEmps;  --     109 строк
SELECT COUNT(*) FROM TestEmps2; --  11 990 строк
SELECT COUNT(*) FROM TestEmps3; -- 275 793 строк

DECLARE
  kek CONSTANT SIMPLE_INTEGER := 42;
BEGIN
  EXECUTE IMMEDIATE 'BEGIN DBMS_OUTPUT.PUT_LINE(''kek: :1''); END;' USING kek;
  DBMS_OUTPUT.PUT_LINE('done!');
END;
/

DROP TABLE TestEmps PURGE;
CREATE TABLE TestEmps AS
  SELECT * FROM Employees;

DROP TABLE TestEmps2 PURGE;
CREATE TABLE TestEmps2 AS
  SELECT * FROM TestEmps
  CONNECT BY LEVEL <= 2;

DROP TABLE TestEmps3 PURGE;
CREATE TABLE TestEmps3 AS
  SELECT * FROM TestEmps
  START WITH Employee_ID > 185
  CONNECT BY LEVEL <= 3;

TRUNCATE TABLE Duplicates;
EXECUTE generate.rows(10**7);

BEGIN
  DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
  -- distinctDSQL('Duplicates');
  distinctDBMS_SQL('Duplicates');
  DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

SELECT COUNT(*) FROM Duplicates;