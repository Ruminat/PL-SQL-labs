DECLARE
  today DATE := SYSDATE;
  tomorrow today%type;
BEGIN
  tomorrow := today + 1;
  DBMS_OUTPUT.PUT_LINE('Hello, World!');
  DBMS_OUTPUT.PUT_LINE('Today is ' || today || ' and tomorrow is ' || tomorrow);
END;