ACCEPT empno NUMBER PROMPT 'Укажите номер сотрудника';
DECLARE
  fname VARCHAR2(15);
  emp_sal NUMBER(10);
BEGIN
  SELECT first_name, salary
  INTO fname, emp_sal FROM employees
  WHERE employee_id = &&empno;
  DBMS_OUTPUT.PUT_LINE('Hello, ' || fname);
  DBMS_OUTPUT.PUT_LINE('YOUR SALARY IS: ' || emp_sal);
  DBMS_OUTPUT.PUT_LINE(
       'YOUR CONTRIBUTION TOWARDS PF: '
    || ROUND((0.12 * 0.45) * emp_sal, 1)
  );
END;
/