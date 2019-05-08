ALTER SESSION SET PLSQL_CCFLAGS = 'my_debug:FALSE, my_tracing:FALSE';
CREATE OR REPLACE PACKAGE my_pkg AS
  SUBTYPE my_real IS
    $IF DBMS_DB_VERSION.VERSION < 10 $THEN NUMBER; -- check database version
      $ELSE                                BINARY_DOUBLE;
    $END
  my_pi my_real; my_e my_real;
END my_pkg;
/
CREATE OR REPLACE PACKAGE BODY my_pkg AS
BEGIN 
  $IF DBMS_DB_VERSION.VERSION < 10 $THEN
       my_pi := 3.14016408289008292431940027343666863227;
       my_e  := 2.71828182845904523536028747135266249775;
  $ELSE
       my_pi := 3.14016408289008292431940027343666863227d;
       my_e  := 2.71828182845904523536028747135266249775d;
  $END
END my_pkg;
/

CREATE OR REPLACE PROCEDURE circle_area(radius my_pkg.my_real) IS
  my_area my_pkg.my_real;
  my_datatype VARCHAR2(30);
BEGIN
  my_area := my_pkg.my_pi * radius;
  DBMS_OUTPUT.PUT_LINE('Radius: ' || TO_CHAR(radius) 
                       || ' Area: ' || TO_CHAR(my_area) );

  $IF $$my_debug $THEN -- if my_debug is TRUE, run some debugging code
    SELECT DATA_TYPE INTO my_datatype FROM USER_ARGUMENTS 
       WHERE OBJECT_NAME = 'CIRCLE_AREA' AND ARGUMENT_NAME = 'RADIUS';
     DBMS_OUTPUT.PUT_LINE('Datatype of the RADIUS argument is: ' || my_datatype);
  $END
END;
/
