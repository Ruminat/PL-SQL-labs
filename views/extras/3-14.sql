-- Создание процедуры.
CREATE OR REPLACE PROCEDURE
  dop_3_14 (fromCity Paths.Acity%TYPE, toCity Paths.Bcity%TYPE) IS
  
  TYPE passedCitiesTable IS TABLE OF BOOLEAN INDEX BY SIMPLE_INTEGER;
  passed passedCitiesTable; -- Таблица городов, которые мы уже проехали.
  
  TYPE reachableCitiesTable IS TABLE OF Paths.Dist%TYPE      INDEX BY SIMPLE_INTEGER;
  TYPE citiesTable          IS TABLE OF reachableCitiesTable INDEX BY SIMPLE_INTEGER;
  cities citiesTable; -- Таблица дистанций между городами.

  TYPE citiesList IS TABLE OF SIMPLE_INTEGER;
  TYPE pathRecord IS RECORD (
    cities citiesList
  , dist   SIMPLE_INTEGER := 0
  );
  TYPE pathsTable IS TABLE OF pathRecord;
  -- Таблица всех путей от города fromCity к toCity,
  -- В каждом из путей хранятся лишь промежуточные города.
  allPaths pathsTable := pathsTable();

  TYPE cityNamesTable IS TABLE OF Paths.Acity%TYPE INDEX BY SIMPLE_INTEGER;
  cityNames cityNamesTable; -- Таблица названий городов.

  fromID Paths.AID%TYPE; -- ID города, из которого выезжаем.
  toID   Paths.BID%TYPE; -- ID города, в который приезжаем.

  -- Сообщение об ошибке.
  PROCEDURE error (message VARCHAR2) IS BEGIN
    DBMS_OUTPUT.PUT_LINE('Dop_3_14(''' || fromCity || ''', ''' || toCity || ''') error:');
    DBMS_OUTPUT.PUT_LINE('  ' || message);
  END;
  -- Объехать города.
  PROCEDURE traverse (
        ID SIMPLE_INTEGER
  , pathIN pathRecord
  , dist   SIMPLE_INTEGER
  ) IS
    currentDest PLS_INTEGER := cities(ID).FIRST; -- Следующий город, в который поедем.
    path pathRecord := pathIN; -- Текущий путь (который, возможно, будет добавлен в allPaths).
  BEGIN
    -- Если мы уже проехали этот город, то дальше не едем.
    IF passed.EXISTS(ID) AND passed(ID) = TRUE THEN RETURN; END IF;

    -- Добавляем город к путю.
    path.dist := path.dist + dist;
    path.cities.EXTEND;
    path.cities(path.cities.LAST) := ID;

    -- Если мы доехали до пункта назначения, то добавляем путь к allPaths.
    IF ID = toID THEN
      allPaths.EXTEND;
      allPaths(allPaths.LAST) := path;
    RETURN; END IF;
    
    -- Рекурсивно объезжаем всевозможные доступные города.
    passed(ID) := TRUE;
    WHILE currentDest IS NOT NULL LOOP
      traverse(currentDest, path, cities(ID)(currentDest));
      currentDest := cities(ID).NEXT(currentDest);
    END LOOP;
    passed(ID) := FALSE;
  END;
BEGIN
  -- Проверяем, не совпадают ли пункт отправления и назначения.
  IF fromCity = toCity THEN
    error('it makes no sense in going from ' || fromCity || ' to ' || toCity || '.');
  RETURN; END IF;

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

    -- Заполняем названия городов (если ещё не заполнили).
    IF NOT cityNames.EXISTS(row.AID) THEN
      cityNames(row.AID) := row.Acity; END IF;
    IF NOT cityNames.EXISTS(row.BID) THEN
      cityNames(row.BID) := row.Bcity; END IF;

    -- Выдаём ошибку, если города с одинаковыми ID имеют разные названия.
    IF cityNames(row.AID) != row.Acity THEN
      error('names of cities with ID '|| row.AID ||' do not match.');        
    RETURN; END IF;
    IF cityNames(row.BID) != row.Bcity THEN
      error('names of cities with ID '|| row.BID ||' do not match.');        
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
  IF cities.COUNT = 0 THEN
    error('there are no cities in the Paths table.');
    RETURN; END IF;
  -- Проверяем, есть ли заданные города в таблице Paths.
  IF fromID IS NULL THEN
    error('there is no such city as ' || fromCity || ' in Paths table.');
    RETURN; END IF;
  IF toID IS NULL THEN
    error('there is no such city as ' || toCity   || ' in Paths table.');
    RETURN; END IF;  


  DECLARE
    path pathRecord := pathRecord(citiesList());
    TYPE pathsTable IS TABLE OF VARCHAR2(8192);
    paths pathsTable := pathsTable(); 
    maxLength SIMPLE_INTEGER := LENGTH('Маршруты ' || fromCity || ' — ' || toCity);
    padding VARCHAR2(64) := '  ';
  BEGIN
    -- Объезжаем все города.
    traverse(fromID, path, 0);

    -- Если не найдено ни одного пути.
    IF allPaths.COUNT = 0 THEN
      DBMS_OUTPUT.PUT_LINE(
           'Не найдено ни одного маршрута между городами '
        || fromCity || ' и ' || toCity || '.'
      );
    RETURN; END IF;

    -- Заполняем строки маршрутов и находим максимальную длину строки маршрутов.
    FOR i IN allPaths.FIRST..allPaths.LAST LOOP
      paths.EXTEND;
      paths(paths.LAST) := padding;
      FOR j IN allPaths(i).cities.FIRST..allPaths(i).cities.LAST - 1 LOOP
        paths(paths.LAST) := paths(paths.LAST) || cityNames(allPaths(i).cities(j)) || ' ';
      END LOOP;
      paths(paths.LAST) := paths(paths.LAST) || cityNames(allPaths(i).cities(allPaths(i).cities.LAST));
      IF LENGTH(paths(paths.LAST)) > maxLength THEN
        maxLength := LENGTH(paths(paths.LAST));
      END IF;
    END LOOP;

    -- Выводим все пути.
    DBMS_OUTPUT.PUT_LINE(
         RPAD('Маршруты ' || fromCity || ' — ' || toCity, maxLength + 3, ' ')
      || 'Длина маршрута'
    );
    FOR i IN paths.FIRST..paths.LAST LOOP
      DBMS_OUTPUT.PUT_LINE(RPAD(paths(i), maxLength + 3, ' ') || allPaths(i).dist);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Всего ' || allPaths.LAST || ' вариантов маршрута.');
  END;

-- Если возникли какие-то другие ошибки.
EXCEPTION
  WHEN OTHERS THEN
    error('something went wrong...');
END dop_3_14;
/


-- Вызов процедуры.
BEGIN
  dop_3_14('Pskov', 'Vologda');
END;