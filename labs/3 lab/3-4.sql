-- VARIABLE basic_perсent NUMBER;
-- VARIABLE pf_percent    NUMBER;
DECLARE
  -- today DATE := SYSDATE;
  -- tomorrow today%type;
  fname VARCHAR2(15);
  emp_sal NUMBER(10);
BEGIN
  -- :basic_perсent := 45;
  -- :pf_percent    := 12;
  -- tomorrow       := today + 1;
  SELECT first_name, salary
  INTO fname, emp_sal FROM employees
  WHERE employee_id=110;
  DBMS_OUTPUT.PUT_LINE('Hello, ' || fname);
  DBMS_OUTPUT.PUT_LINE('YOUR SALARY IS: ' || emp_sal);
  DBMS_OUTPUT.PUT_LINE(
       'YOUR CONTRIBUTION TOWARDS PF: '
    || ROUND((0.12 * 0.45) * emp_sal, 1)
  );
  -- DBMS_OUTPUT.PUT_LINE('Today is ' || today || ' and tomorrow is ' || tomorrow);
END;
/
-- PRINT basic_perсent pf_percent;