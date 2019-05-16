BEGIN
  $IF DBMS_DB_VERSION.VER_LE_10_1 $THEN
    DBMS_OUTPUT.PUT_LINE('Unsupported database release');
  $ELSE
    DBMS_OUTPUT.PUT_LINE(
         'Release '
      || DBMS_DB_VERSION.VERSION ||'.'|| DBMS_DB_VERSION.RELEASE
      || ' is supported'
    );
  $END
END;
/