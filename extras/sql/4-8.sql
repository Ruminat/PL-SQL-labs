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