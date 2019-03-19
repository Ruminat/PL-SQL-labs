DECLARE
  str       VARCHAR2(32767) := '(a + b)^2 = a^2 + 2ab + b^2';
  -- str       VARCHAR2(32767) := '123412314231243121342132413214321';
  -- str       VARCHAR2(32767); -- текущая строка
  substring VARCHAR2(16384); -- текущая подстрока
  len         NUMBER; -- длина строки
  maxLength   NUMBER; -- максимально возможная длина подстроки
  maxStartPos NUMBER; -- максимальная стартовая позиция подстроки
  occurrings  NUMBER; -- количество вхождений подстроки в строку
BEGIN
  -- можно ли найти в строке необходимые подстроки
  IF (str IS NULL OR LENGTH(str) < 2) THEN
    DBMS_OUTPUT.PUT_LINE('-');
  ELSE
    len := LENGTH(str);
    maxLength := FLOOR(len / 2);
    FOR currentLength IN REVERSE 1..maxLength LOOP
      -- EXIT WHEN currentLength < foundLegth;
      maxStartPos := len - currentLength + 1;
      FOR startPos IN 1..maxStartPos LOOP
        substring := SUBSTR(str, startPos, currentLength);
        occurrings := ( -- кол-во вхождений = (длина - длина_без_подстроки) / длина_подстроки
            len - LENGTH(REPLACE(LOWER(str), LOWER(substring)))
          ) / LENGTH(substring);
        CONTINUE WHEN occurrings != 2;
        DBMS_OUTPUT.PUT_LINE(
             'substring = ''' || substring
          || '''; startPos = ' || startPos
          || '; length = ' || currentLength
        );
      END LOOP;
    END LOOP;
  END IF;
END;
/