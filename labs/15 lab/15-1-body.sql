CREATE OR REPLACE PACKAGE BODY table_pkg IS
  
  PROCEDURE make (table_name VARCHAR2, col_specs VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE '|| table_name ||' ('|| col_specs ||')';
  END;

  PROCEDURE add_row (table_name VARCHAR2, col_values VARCHAR2, cols VARCHAR2 := NULL) IS
    statement VARCHAR2(512) := 'INSERT INTO '|| table_name; 
  BEGIN
    IF cols IS NOT NULL THEN
      statement := statement ||' ('|| cols ||')';
    END IF;
    EXECUTE IMMEDIATE statement ||' VALUES ('|| col_values ||')';
  END;

  PROCEDURE upd_row (table_name VARCHAR2, set_values VARCHAR2, conditions VARCHAR2 := NULL) IS
    statement VARCHAR2(512) := 'UPDATE '|| table_name ||' SET '|| set_values;
  BEGIN
    IF conditions IS NOT NULL THEN 
      statement := statement ||' WHERE '|| conditions;
    END IF;
    EXECUTE IMMEDIATE statement;
  END;

  PROCEDURE del_row (table_name VARCHAR2, conditions VARCHAR2 := NULL) IS
    statement VARCHAR2(512) := 'DELETE FROM '|| table_name;
  BEGIN
    IF conditions IS NOT NULL THEN
      statement := statement ||' WHERE '|| conditions;
    END IF;
    EXECUTE IMMEDIATE statement;
  END;

  PROCEDURE remove (table_name VARCHAR2) IS
    cursorID PLS_INTEGER;
  BEGIN
    cursorID := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(cursorID, 'DROP TABLE '|| table_name, DBMS_SQL.NATIVE);
    DBMS_SQL.CLOSE_CURSOR(cursorID);
  END;

END table_pkg;
/