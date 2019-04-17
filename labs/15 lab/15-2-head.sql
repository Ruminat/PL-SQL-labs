CREATE OR REPLACE PACKAGE compile_pkg IS
  PROCEDURE make (objectName USER_SOURCE.Name%TYPE);
END compile_pkg;
/