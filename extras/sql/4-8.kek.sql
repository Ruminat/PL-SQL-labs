SELECT COUNT(*) FROM TestEmps;  --     109 строк
SELECT COUNT(*) FROM TestEmps2; --  11 990 строк
SELECT COUNT(*) FROM TestEmps3; -- 275 793 строк

DROP TABLE TestEmps PURGE;
CREATE TABLE TestEmps AS
  SELECT * FROM Employees;

DROP TABLE TestEmps2 PURGE;
CREATE TABLE TestEmps2 AS
  SELECT * FROM TestEmps
  CONNECT BY LEVEL <= 2;

DROP TABLE TestEmps3 PURGE;
CREATE TABLE TestEmps3 AS
  SELECT * FROM TestEmps
  START WITH Employee_ID > 185
  CONNECT BY LEVEL <= 3;

TRUNCATE TABLE Duplicates;
EXECUTE generate.rows(1000);
-- SELECT * FROM Duplicates;

DECLARE
  startTimestamp TIMESTAMP;
BEGIN
  startTimestamp := SYSTIMESTAMP;
  -- distinctDSQL('TestEmps');
  distinctDBMS_SQL('TestEmps');
  DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP - startTimestamp);
END;
/

SELECT COUNT(*) FROM TestEmps;