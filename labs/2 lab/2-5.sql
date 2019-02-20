VARIABLE basic_perсent NUMBER;
VARIABLE pf_percent    NUMBER;
DECLARE
  today DATE := SYSDATE;
  tomorrow today%type;
BEGIN
	:basic_perсent := 45;
	:pf_percent    := 12;
	tomorrow       := today + 1;
  DBMS_OUTPUT.PUT_LINE('Hello, World!');
  DBMS_OUTPUT.PUT_LINE('Today is ' || today || ' and tomorrow is ' || tomorrow);
END;
/
PRINT basic_perсent pf_percent;