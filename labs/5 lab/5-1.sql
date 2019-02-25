BEGIN
  FOR i IN 1..10 LOOP
    CONTINUE WHEN i IN (6, 8);
    INSERT INTO Messages (Results) VALUES (i);
  END LOOP;
END;
/

COMMIT;

SELECT *
FROM Messages;