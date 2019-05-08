CREATE OR REPLACE PACKAGE testPackage IS
  PROCEDURE my_proc_pack;
END testPackage;
/
CREATE OR REPLACE PACKAGE BODY testPackage IS
  PROCEDURE my_proc_pack IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('I say! I''m testPackage.my_proc_pack!');
    DBMS_OUTPUT.PUT_LINE('I''m a completely different procedure now!');
  END;
END testPackage;
/

CREATE OR REPLACE
PROCEDURE my_proc IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('Hello there, I''m my_proc!');
  DBMS_OUTPUT.PUT_LINE('I want to call the testPackage.my_proc_pack.');
  testPackage.my_proc_pack;
END;
/

BEGIN
  my_proc;
END;
/