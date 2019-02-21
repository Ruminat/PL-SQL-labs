DECLARE
  weight NUMBER(3) := 600;
  message VARCHAR2(255) := 'Product 10012';
BEGIN
  DECLARE
    weight NUMBER(3) := 1;
    message VARCHAR2(255) := 'Product 11001';
    new_locn VARCHAR2(50) := 'Europe';
  BEGIN
    weight := weight + 1;
    new_locn := 'Western ' || new_locn;
    DBMS_OUTPUT.PUT_LINE('(1) weight = ' || weight);
    DBMS_OUTPUT.PUT_LINE('(1) new_locn = ' || new_locn);
    /*(1)*/
  END;
  weight := weight + 1;
  message := message || ' is in stock';
  -- new_locn := 'Western ' || new_locn;
  DBMS_OUTPUT.PUT_LINE('(2) weight = ' || weight);
  DBMS_OUTPUT.PUT_LINE('(2) message = ' || message);
  /*(2)*/
END;
/