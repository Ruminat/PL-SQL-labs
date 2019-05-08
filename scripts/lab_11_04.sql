DECLARE
-- the package_text variable contains the text to create the package spec and body
  package_text VARCHAR2(32767);
  FUNCTION generate_spec (pkgname VARCHAR2) RETURN VARCHAR2 AS
  BEGIN
     RETURN 'CREATE PACKAGE ' || pkgname || ' AS
       PROCEDURE raise_salary (emp_id NUMBER, amount NUMBER);
       PROCEDURE fire_employee (emp_id NUMBER);
       END ' || pkgname || ';';
  END generate_spec;
  
FUNCTION generate_body (pkgname VARCHAR2) RETURN VARCHAR2 AS
  BEGIN
     RETURN 'CREATE PACKAGE BODY ' || pkgname || ' AS

     PROCEDURE raise_salary (emp_id NUMBER, amount NUMBER) IS
       BEGIN
         UPDATE employees SET salary = salary + amount WHERE employee_id = emp_id;
       END raise_salary;
     PROCEDURE fire_employee (emp_id NUMBER) IS
       BEGIN
         DELETE FROM employees WHERE employee_id = emp_id;
       END fire_employee;
     END ' || pkgname || ';';
  END generate_body;
