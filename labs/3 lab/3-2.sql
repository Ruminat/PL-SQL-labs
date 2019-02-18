DECLARE
  customer VARCHAR2(50) := 'Womansport';
  credit_rating VARCHAR2(50) := 'EXCELLENT';
BEGIN
  DECLARE
    customer NUMBER(7) := 201;
    name VARCHAR2(25) := 'Unisports';
  BEGIN
    credit_rating :='GOOD';
    DBMS_OUTPUT.PUT_LINE('nested customer = ' || customer || ', type = NUMBER(7)');
    DBMS_OUTPUT.PUT_LINE('nested credit_rating = ' || credit_rating || ', type = VARCHAR2(50)');
  END;
  DBMS_OUTPUT.PUT_LINE('main customer = ' || customer || ', type = VARCHAR2(50)');
  DBMS_OUTPUT.PUT_LINE('main name is not accessible in this block');
  DBMS_OUTPUT.PUT_LINE('main credit_rating = ' || credit_rating || ', type = VARCHAR2(50)');
END;
/