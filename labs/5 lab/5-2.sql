DEFINE empno = 176

DECLARE
  empno NUMBER;
  asteriks Emp.Stars%TYPE := NULL;
  sal      Emp.Salary%TYPE;
BEGIN
  empno := &empno;

  SELECT Salary
  INTO   sal
  FROM Emp
  WHERE Employee_ID = empno;

  FOR i IN 1..NVL(FLOOR(sal / 1000), 0) LOOP
    asteriks := asteriks || '*';
  END LOOP;

  UPDATE Emp SET Stars = asteriks WHERE Employee_ID = empno;
END;
/

SELECT Employee_ID, Salary, Stars
FROM Emp
WHERE Employee_ID = &empno;