CREATE OR REPLACE PACKAGE table_pkg IS
  PROCEDURE make    (table_name VARCHAR2, col_specs  VARCHAR2);
  PROCEDURE add_row (table_name VARCHAR2, col_values VARCHAR2, cols       VARCHAR2 := NULL);
  PROCEDURE upd_row (table_name VARCHAR2, set_values VARCHAR2, conditions VARCHAR2 := NULL);
  PROCEDURE del_row (table_name VARCHAR2, conditions VARCHAR2 := NULL);
  PROCEDURE remove  (table_name VARCHAR2);
END table_pkg;
/