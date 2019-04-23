DECLARE
  -- типы данных для итогового вывода
  TYPE outputRow IS TABLE OF VARCHAR2(4096);
  TYPE outputRowLengths IS TABLE OF NUMBER
    INDEX BY PLS_INTEGER;
  
  header outputRow := outputRow('Строка', 'Подстрока', 'Номер позиции начала 1', 'Номер позиции начала 2');
  lengths outputRowLengths;

  TYPE outputTable IS TABLE OF outputRow
    INDEX BY PLS_INTEGER;

  -- таблица строк на вывод (результат алгоритма)
  result outputTable;

  -- типы данных для хранения подстрок для каждой строки
  TYPE substring IS RECORD (
    value Dop_2_26.Строка%TYPE,
    startPos1 NUMBER,
    startPos2 NUMBER
  );
  TYPE substringsTable IS TABLE OF substring
    INDEX BY PLS_INTEGER;
  TYPE stringsTable IS TABLE OF substringsTable
    INDEX BY Dop_2_26.Строка%TYPE;
  
  -- словарь из заданных строк к списку их подстрок
  substrings stringsTable;

  str Dop_2_26.Строка%TYPE; -- текущая строка
  sub Dop_2_26.Строка%TYPE; -- текущая подстрока
  len         NUMBER; -- длина строки
  occurrings  NUMBER; -- количество вхождений подстроки в строку
  foundLength NUMBER; -- максимально найденная длина подстроки
  startPos2   NUMBER; -- начальная позиция 2-ой подстроки
  newSub      NUMBER; -- индекс текущей подстроки
BEGIN
  -- заполняем длины столбцов выводимой таблицы длинами заголовка
  FOR i IN 1..header.LAST LOOP
    lengths(i) := LENGTH(header(i));
  END LOOP;

  -- обрабатываем строки
  FOR row IN (SELECT Строка FROM Dop_2_26) LOOP
    str := row.Строка;
    -- если в строке нельзя найти необходимые подстроки
    IF str IS NULL OR LENGTH(str) < 2 THEN
      result(NVL(result.LAST + 1, 1)) := outputRow(NVL(str, '(null)'), '-', '-', '-');
      CONTINUE;
    END IF;
    substrings(str) := substringsTable();
    foundLength := NULL;
    len := LENGTH(str);
    FOR currentLength IN REVERSE 1..(FLOOR(len / 2)) LOOP
      EXIT WHEN currentLength < foundLength;
      &lt&ltposLoop&gt&gt FOR startPos IN 1..(len - currentLength + 1)
      LOOP
        sub := SUBSTR(str, startPos, currentLength);
        occurrings := ( -- кол-во вхождений = (длина - длина_без_подстроки) / длина_подстроки
            len - LENGTH(REPLACE(LOWER(str), LOWER(sub)))
          ) / LENGTH(sub);
        startPos2 := INSTR(str, sub, startPos + currentLength);
        -- если вхождений не 2 или 2-ое вхождение расположено не после конца 1-го
        CONTINUE WHEN occurrings != 2 OR startPos2 = 0;
        -- проверяем, пересекаются ли 2 текущие подстроки с уже найденными
        FOR i IN 1..NVL(substrings(str).LAST, 0) LOOP
          CONTINUE posLoop WHEN
               startPos  BETWEEN
                     substrings(str)(i).startPos1
                 AND substrings(str)(i).startPos1 + currentLength - 1
            OR startPos  BETWEEN
                     substrings(str)(i).startPos2
                 AND substrings(str)(i).startPos2 + currentLength - 1
            OR startPos2 BETWEEN
                     substrings(str)(i).startPos1
                 AND substrings(str)(i).startPos1 + currentLength - 1
            OR startPos2 BETWEEN
                     substrings(str)(i).startPos2
                 AND substrings(str)(i).startPos2 + currentLength - 1;
        END LOOP;
        -- индекс новой подстроки
        newSub := NVL(substrings(str).LAST + 1, 1);
        -- добавляем подстроку к списку
        substrings(str)(newSub) := substring(sub, startPos, startPos2);
        -- добавляем новую строку в вывод
        IF newSub = 1 THEN
          result(NVL(result.LAST + 1, 1)) := outputRow(str, sub, startPos, startPos2);
        ELSE
          result(NVL(result.LAST + 1, 1)) := outputRow(' ', sub, startPos, startPos2);
        END IF;
        foundLength := currentLength;
      END LOOP posLoop;
    END LOOP;
    -- если не нашли ни одной подходящей подстроки
    IF substrings(str).COUNT = 0 THEN
      result(NVL(result.LAST + 1, 1)) := outputRow(str, '-', '-', '-');
    END IF;
  END LOOP;

  -- вывод результата
  DECLARE
    rowOutput      VARCHAR2(4096); -- текущая выводимая строка
    horizontalRule VARCHAR2(4096); -- горизонтальная черта в таблице
  BEGIN
    -- находим длины столбцов таблицы
    FOR row IN 1..result.LAST LOOP
      FOR col IN 1..result(row).LAST LOOP
        IF LENGTH(result(row)(col)) > lengths(col) THEN
          lengths(col) := LENGTH(result(row)(col));
        END IF;
      END LOOP;
    END LOOP;

    -- выводим заголовок таблицы
    FOR i IN 1..(header.LAST - 1) LOOP
      rowOutput := rowOutput || RPAD(header(i), lengths(i), ' ') || ' | ';
    END LOOP;
    rowOutput := rowOutput || header(header.LAST);
    DBMS_OUTPUT.PUT_LINE(rowOutput);

    -- заполняем переменную «горизонтальная линия» (horizontalRule)
    FOR i IN 1..(header.LAST - 1) LOOP
      horizontalRule := horizontalRule || RPAD('-', lengths(i), '-') || '-|-';
    END LOOP;
    horizontalRule := horizontalRule || RPAD('-', lengths(lengths.LAST), '-');

    -- выводим таблицу result
    FOR row IN 1..result.LAST LOOP
      DBMS_OUTPUT.PUT_LINE(horizontalRule);
      rowOutput := '';
      FOR col IN 1..(result(row).LAST - 1) LOOP
        rowOutput := rowOutput || RPAD(result(row)(col), lengths(col), ' ') || ' | ';
      END LOOP;
      rowOutput := rowOutput || result(row)(result(row).LAST);
      DBMS_OUTPUT.PUT_LINE(rowOutput);
    END LOOP;
  END;
END;
/