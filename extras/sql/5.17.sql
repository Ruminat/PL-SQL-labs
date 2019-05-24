-- CREATE TABLE Батька (
--    ID NUMBER(10) PRIMARY KEY
--  , Phrase VARCHAR2(1023)
-- );

-- CREATE TABLE Сына (
--    ID NUMBER(10) REFERENCES Батька (ID)
--  , Reaction VARCHAR2(1023)
-- );

-- INSERT INTO Батька
--             SELECT 1, 'Алё блять!'     FROM dual
--   UNION ALL SELECT 2, 'Слышь, хуйло!'  FROM dual
--   UNION ALL SELECT 3, 'Ебало на ноль!' FROM dual;

-- INSERT INTO Сына
--             SELECT 1, 'Ну что там?' FROM dual
--   UNION ALL SELECT 2, 'Бля...'      FROM dual
--   UNION ALL SELECT 3, '...'         FROM dual;

-- TRUNCATE TABLE Сына;

SELECT *
FROM Батька JOIN Сына USING (ID);

SET CONSTRAINTS ALL DEFERRED;

UPDATE Сына SET ID = ID + 1;
UPDATE Батька SET ID = ID + 1;