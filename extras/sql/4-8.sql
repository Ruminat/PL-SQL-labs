CREATE OR REPLACE PACKAGE generate IS
  PROCEDURE rows (n SIMPLE_INTEGER := 0);
END;
/

CREATE OR REPLACE PACKAGE BODY generate IS
  TYPE rowsT IS TABLE OF SIMPLE_INTEGER;

  PROCEDURE rows (n SIMPLE_INTEGER := 0) IS
    rowsTable rowsT := rowsT();
    maxValue  SIMPLE_INTEGER := 1;
    rowsCount SIMPLE_INTEGER := 0;
  BEGIN
    rowsTable.EXTEND(n);
    <<mainLoop>> WHILE TRUE LOOP
      FOR i IN 1..maxValue LOOP
        EXIT mainLoop WHEN rowsCount >= n;
        rowsCount := rowsCount + 1;
        rowsTable(rowsCount) := i;
      END LOOP;
      maxValue := maxValue + 1;
    END LOOP mainLoop;

    FORALL i IN 1..n
      SAVE EXCEPTIONS
      INSERT INTO Duplicates VALUES (rowsTable(i));
  END;
END;
/



TRUNCATE TABLE Duplicates;
EXECUTE generate.rows(1000);

SELECT * FROM Duplicates;

-- DELETE FROM Duplicates WHERE 