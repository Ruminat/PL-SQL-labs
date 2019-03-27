SELECT
  Last_Name                               AS "Employee"      ,
  Salary                                  AS "Salary"        ,
  NVL(TO_CHAR(Commission_PCT), ' ')       AS "Commission_PCT",
  get_annual_comp(Salary, Commission_PCT) AS "Result" 
FROM Employees
WHERE Department_ID = 30;