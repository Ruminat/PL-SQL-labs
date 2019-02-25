DECLARE
  -- Department table type
  TYPE dept_table_type IS TABLE OF
    Departments.Department_Name%TYPE
    INDEX BY PLS_INTEGER;
  -- Department table
  my_dept_table dept_table_type;
  
  -- useless variables
  loop_count NUMBER := 10;
  deptno     NUMBER := 0;
BEGIN
  FOR i IN 1..10 LOOP
    SELECT Department_Name
    INTO   my_dept_table(i)
    FROM Departments
    WHERE Department_ID = 10*i;
  END LOOP;

  FOR i IN my_dept_table.FIRST..my_dept_table.LAST LOOP
    DBMS_OUTPUT.PUT_LINE(my_dept_table(i));
  END LOOP;
END;