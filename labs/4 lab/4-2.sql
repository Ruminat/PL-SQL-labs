VARIABLE dept_id NUMBER;
DECLARE
  max_deptno NUMBER;
  dept_name Departments.Department_Name%TYPE := 'Education';
BEGIN
  SELECT MAX(Department_ID)
  INTO max_deptno
  FROM Departments;

  :dept_id := max_deptno + 10;
  
  INSERT INTO Departments (Department_ID, Department_Name, Location_ID)
  VALUES                  (:dept_id,      dept_name,       NULL       );
  
  DBMS_OUTPUT.PUT_LINE('The maximum department_id is: ' || max_deptno);
  DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' row(s) added');
END;
/

SELECT *
FROM Departments;