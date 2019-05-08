CREATE OR REPLACE PACKAGE BODY compile_pkg IS
 
  /*
    --- PRIVATE ---
  */

  FUNCTION get_type (objectName USER_SOURCE.Name%TYPE)
  RETURN USER_SOURCE.Type%TYPE IS
    objectType USER_SOURCE.Type%TYPE;
  BEGIN
    SELECT DISTINCT Type
    INTO      objectType
    FROM USER_SOURCE
    WHERE Name = UPPER(objectName) AND Type != 'PACKAGE BODY';

    RETURN objectType;

  EXCEPTION
    WHEN OTHERS THEN RETURN NULL;
  END;

  /*
    --- PUBLIC ---
  */

  PROCEDURE make (objectName USER_SOURCE.Name%TYPE) IS
    objectType USER_SOURCE.Type%TYPE := get_type(objectName);
    statement VARCHAR2(256);
  BEGIN
    IF objectType IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('compile_pkg.make('''|| objectName ||''') error:');
      DBMS_OUTPUT.PUT_LINE('- the type of '|| objectName ||' was not found.');
    RETURN; END IF;

    statement := 'ALTER '|| objectType ||' '|| objectName ||' COMPILE';
    IF objectType != 'PACKAGE' THEN
      EXECUTE IMMEDIATE statement;
      DBMS_OUTPUT.PUT_LINE('Compiled '|| objectName ||'.');
    ELSE
      EXECUTE IMMEDIATE statement || ' SPECIFICATION';
      EXECUTE IMMEDIATE statement || ' BODY';
      DBMS_OUTPUT.PUT_LINE('Compiled '|| objectName ||'''s specification and body.');
    END IF;
  END;

  PROCEDURE recompile IS
    objectType USER_SOURCE.Type%TYPE;
    statement VARCHAR2(256);
  BEGIN
    FOR queryRow IN (
      SELECT *
      FROM USER_OBJECTS
      WHERE Status = 'INVALID'
    ) LOOP
      objectType := REGEXP_SUBSTR(queryRow.Object_Type, '\w+', 1, 1);
      statement  := 'ALTER '|| objectType ||' '|| queryRow.Object_Name;
      IF objectType = 'PACKAGE' THEN
        EXECUTE IMMEDIATE statement ||' COMPILE SPECIFICATION';    
        EXECUTE IMMEDIATE statement ||' COMPILE BODY';    
      ELSE
        EXECUTE IMMEDIATE statement ||' COMPILE';    
      END IF;
    END LOOP;
  END;

END compile_pkg;
/

BEGIN
  compile_pkg.recompile;
END;
/