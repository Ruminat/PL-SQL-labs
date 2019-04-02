-- Создание процедуры.
CREATE OR REPLACE PROCEDURE
  dop_3_14 (fromCity Paths.Acity%TYPE, toCity Paths.Bcity%TYPE) IS
  
  TYPE passedCitiesTable IS TABLE OF BOOLEAN
    INDEX BY PLS_INTEGER;

  TYPE reachableCitiesTable IS TABLE OF Paths.Dist%TYPE
    INDEX BY PLS_INTEGER;

  TYPE citiesTable IS TABLE OF reachableCitiesTable
    INDEX BY PLS_INTEGER;

  cities citiesTable;       -- Таблица дистанций между городами.
  passed passedCitiesTable; -- Таблица городов, которые мы уже проехали.
  -- Таблица всех путей от города fromCity к toCity,
  -- в каждом из путей хранятся лишь промежуточные города.
  allPaths citiesTable;

  fromID Paths.AID%TYPE; -- ID города, из которого выезжаем.
  toID   Paths.BID%TYPE; -- ID города, в который приезжаем.

  -- Сообщение об ошибке.
  PROCEDURE error (message VARCHAR2) IS BEGIN
    DBMS_OUTPUT.PUT_LINE('Dop_3_14(''' || fromCity || ''', ''' || toCity || ''') error:');
    DBMS_OUTPUT.PUT_LINE('  ' || message);
  END;
  -- Объехать города.
  PROCEDURE traverse (currentID PLS_INTEGER) IS BEGIN
    passed(currentID) = TRUE;
    IF currentID = toID THEN
      
    ELSE
        
    END IF;
    if fromCity == toCity:
      console.put_line(f' {toCity} {dist}')
    else:
      for city in toCity.cities:
        if not passed[city]:
          console.put()
          go(city, Z, passed, dist + city.dist)
    passed(currentID) = FALSE;
  END;
BEGIN
  FOR row IN (SELECT * FROM Paths) LOOP
    -- Если в таблице Paths есть строка с NULL'овым значением.
    IF   row.AID   IS NULL OR row.BID   IS NULL
      OR row.Acity IS NULL OR row.Bcity IS NULL OR row.Dist IS NULL
    THEN
      error(
           'there is a NULL in the Paths table row: '
        || 'AID: '   || NVL(TO_CHAR(row.AID),   '(null)') || ', '
        || 'Acity: ' || NVL(row.Acity,          '(null)') || ', '
        || 'BID: '   || NVL(TO_CHAR(row.BID),   '(null)') || ', '
        || 'Bcity: ' || NVL(row.Bcity,          '(null)') || ', '
        || 'Dist: '  || NVL(TO_CHAR(row.Dist),  '(null)') || '.'
      );
    RETURN; END IF;

    -- Сопоставляем заданным городам их ID (при наличии).
    IF fromID IS NULL THEN
      IF row.Acity = fromCity THEN fromID := row.AID; END IF;
      IF row.Bcity = fromCity THEN fromID := row.BID; END IF;
    END IF;
    IF toID   IS NULL THEN
      IF row.Acity = toCity   THEN toID   := row.AID; END IF;
      IF row.Bcity = toCity   THEN toID   := row.BID; END IF;
    END IF;

    -- Пути работют в обе стороны, то есть AID <-> BID.
    cities(row.AID)(row.BID) := row.Dist;
    cities(row.BID)(row.AID) := row.Dist;
  END LOOP;

  -- Проверяем, есть ли вообще города в таблице Paths.
  IF cities.FIRST IS NULL THEN
    error('there are no cities in the Paths table');
    RETURN; END IF;
  -- Проверяем, есть ли заданные города в таблице Paths
  IF fromID IS NULL THEN
    error('there is no such city as ' || fromCity || ' in Paths table.');
    RETURN; END IF;
  IF toID IS NULL THEN
    error('there is no such city as ' || toCity   || ' in Paths table.');
    RETURN; END IF;


  DBMS_OUTPUT.PUT_LINE('Made it to the end.');

  EXCEPTION
    WHEN OTHERS THEN
      error('something went wrong...');
END dop_3_14;
/


-- Вызов процедуры.
BEGIN
  dop_3_14('Pskov', 'Vologda');
END;