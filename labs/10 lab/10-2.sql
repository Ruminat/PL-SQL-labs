CREATE OR REPLACE FUNCTION
  get_annual_comp (
    sal Employees.Salary%TYPE,
    pct Employees.Commission_PCT%TYPE
  )
RETURN NUMBER IS 
BEGIN
  RETURN (NVL(sal, 0) * 12) + (NVL(pct, 0) * NVL(sal, 0) * 12);
END get_annual_comp;