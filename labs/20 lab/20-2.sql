DECLARE
  PROCEDURE printSource(
     sourceType   VARCHAR2
   , sourceName   VARCHAR2
   , sourceSchema VARCHAR2 := USER
  ) IS
    lines DBMS_PREPROCESSOR.SOURCE_LINES_T;
  BEGIN
    lines := DBMS_PREPROCESSOR.GET_POST_PROCESSED_SOURCE(sourceType, sourceSchema, sourceName);
    FOR i IN 1..lines.COUNT LOOP
      DBMS_OUTPUT.PUT(lines(i));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('');
  END;
BEGIN
  printSource('package',       'my_pkg');
  printSource('package body',  'my_pkg');
  printSource('procedure',     'circle_area');
END;
/