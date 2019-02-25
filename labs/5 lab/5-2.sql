DEFINE empno = 176

DECLARE
  empno NUMBER;
  asteriks Emp.Stars%TYPE := NULL;
  sal      Emp.Salary%TYPE;
BEGIN
  empno := &empno;

  SELECT Salary, TRIM(LPAD(' ', 1 + FLOOR(Salary / 1000), '*'))
  INTO   sal,    asteriks
  FROM Emp
  WHERE Employee_ID = empno;

  UPDATE Emp SET Stars = asteriks WHERE Employee_ID = empno;
END;
/

SELECT Employee_ID, Salary, Stars
FROM Emp
WHERE Employee_ID = &empno;