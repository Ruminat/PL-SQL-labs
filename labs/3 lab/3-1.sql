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
    /*(1)*/
    -- DBMS_OUTPUT.PUT_LINE('weight = ' || weight);
  END;
  weight := weight + 1;
  message := message || ' is in stock';
  new_locn := 'Western ' || new_locn;
  /*(2)*/
END;
/