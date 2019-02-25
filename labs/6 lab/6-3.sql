DECLARE
  -- Department table type
  TYPE dept_table_type IS TABLE OF
    Departments%ROWTYPE
    INDEX BY PLS_INTEGER;
  -- Department table
  my_dept_table dept_table_type;
  
  -- useless variables
  loop_count NUMBER := 10;
  deptno     NUMBER := 0;
BEGIN
  FOR i IN 1..10 LOOP
    SELECT *
    INTO   my_dept_table(i)
    FROM Departments
    WHERE Department_ID = 10*i;
  END LOOP;

  FOR i IN my_dept_table.FIRST..my_dept_table.LAST LOOP
    DBMS_OUTPUT.PUT_LINE(
         'Department Number: ' || my_dept_table(i).Department_ID
      || ' Department Name: '  || my_dept_table(i).Department_Name
      || ' Manager Id: '       || my_dept_table(i).Manager_ID
      || ' Location Id: '      || my_dept_table(i).Location_ID
    );
  END LOOP;
END;