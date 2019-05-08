CREATE OR REPLACE PACKAGE compile_pkg IS
  PROCEDURE make (objectName USER_SOURCE.Name%TYPE);
  PROCEDURE recompile;
END compile_pkg;
/