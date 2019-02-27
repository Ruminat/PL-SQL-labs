DEFINE p_num = &Enter_The_n

TRUNCATE TABLE Top_Salaries;

DECLARE
  num NUMBER := &p_num;
  sal Employees.Salary%TYPE;
  CURSOR emp_cursor IS
    SELECT DISTINCT Salary
    FROM Employees
    ORDER BY Salary DESC;
BEGIN
  OPEN emp_cursor;
  LOOP
    FETCH emp_cursor INTO sal;
    EXIT WHEN emp_cursor%NOTFOUND OR emp_cursor%ROWCOUNT > num;
    INSERT INTO Top_Salaries (Salary) VALUES (sal);
  END LOOP;
  CLOSE emp_cursor;
END;
/

SELECT *
FROM Top_Salaries;