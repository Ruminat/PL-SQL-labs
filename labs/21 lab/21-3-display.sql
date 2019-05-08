CREATE OR REPLACE
PROCEDURE displayInvalidObjects IS
  counter SIMPLE_INTEGER := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('INVALID objects:');
  FOR queryRow IN (
    SELECT *
    FROM USER_OBJECTS
    WHERE Status = 'INVALID'
    ORDER BY Object_Type
  ) LOOP
    counter := counter + 1;
    DBMS_OUTPUT.PUT_LINE(
        ' - '|| queryRow.Object_Type
      ||': ' || queryRow.Object_Name ||' is '|| queryRow.Status
    );
  END LOOP;
  IF counter = 0 THEN
    DBMS_OUTPUT.PUT_LINE('none');      
  END IF;
END;
/

BEGIN
  displayInvalidObjects;
END;
/