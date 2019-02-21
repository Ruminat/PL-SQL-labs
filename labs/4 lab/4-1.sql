DECLARE
  max_deptno NUMBER;
BEGIN
  SELECT MAX(Department_ID)
  INTO max_deptno
  FROM Departments;
  DBMS_OUTPUT.PUT_LINE('The maximum department_id is: ' || max_deptno);
END;