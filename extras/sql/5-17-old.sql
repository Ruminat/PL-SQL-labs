/*
  5.17 Создать триггер, который при создании связи между существующим таблицами
  (команда ALTER TABLE) и создании таблицы со связью
  (команда CREATE TABLE) обеспечит режим каскадного обновления между таблицами.
  Триггер должен работать как при композитной, так и при рекурсивной связях.
  Проверить при одновременном изменении нескольких значений одной командой UPDATE.
*/

DROP TRIGGER UC_After_Create;
DROP TRIGGER UC_Before_Alter;
DROP TRIGGER UC_After_Alter;
DROP TABLE "_UC-constraints" PURGE;

-- Представление, содержащее ограничения в удобной форме.
CREATE OR REPLACE VIEW Constraints_View AS
  SELECT Con.Table_Name
       , Con.Constraint_Name
       , Con.Constraint_Type
       , Con.Status
       , Col.Column_Name
       , Col.Position
       , Con.R_Constraint_Name
  FROM   USER_CONSTRAINTS  Con
    JOIN USER_CONS_COLUMNS Col
      ON Con.Constraint_Name = Col.Constraint_Name;

-- Таблица, хранящая ограничения, которые мы уже обработали триггером,
-- чтобы они могли быть включены в новый триггер Update Cascade (при ALTER TABLE).
CREATE TABLE "_UC-constraints" (
   Main_Table      VARCHAR2(128)
 , Ref_Table       VARCHAR2(128)
 , Constraint_Name VARCHAR2(128)
 , PRIMARY KEY (Main_Table, Ref_Table, Constraint_Name)
);


-- Пакет для организации каскадного обновления (Update Cascade package).
CREATE OR REPLACE PACKAGE UCpkg AUTHID CURRENT_USER IS
  -- Типы пакета.
  SUBTYPE TabNameType   IS USER_TABLES.Table_Name%TYPE;           -- :: String
  SUBTYPE ColNameType   IS USER_TAB_COLUMNS.Column_Name%TYPE;     -- :: String
  SUBTYPE ConNameType   IS USER_CONSTRAINTS.Constraint_Name%TYPE; -- :: String
  SUBTYPE TriggNameType IS USER_OBJECTS.Object_Name%TYPE;         -- :: String
  TYPE ColsList    IS TABLE OF ColNameType;    -- :: [String]
  TYPE StringsList IS TABLE OF VARCHAR2(1024); -- :: [String]
  TYPE RefRecord IS RECORD ( -- :: RefRecord
     conName  ConNameType            -- ::  String
   , mainTab  TabNameType            -- ::  String
   , mainCols ColsList := ColsList() -- :: [String]
   , refTab   TabNameType            -- ::  String
   , refCols  ColsList := ColsList() -- :: [String]
  );
  TYPE RefsList     IS TABLE OF RefRecord; -- :: [RefRecord]
  TYPE TabToRefsMap IS TABLE OF RefsList INDEX BY TabNameType; -- :: {String -> [RefRecord]}

  -- Процедура, обрабатывающая создание (CREATE) таблицы.
  PROCEDURE onCreateTable (tabName TabNameType);
  -- Процедура, срабатывающая перед изменением (ALTER) таблицы.
  PROCEDURE beforeAlterTable  (tabName TabNameType);
  -- Процедура, обрабатывающая изменение (ALTER) таблицы.
  PROCEDURE onAlterTable  (tabName TabNameType);

  -- Возвращает список таблиц со столбцами, от которых tabName зависит по FK.
  -- getRefs :: String -> [RefRecord]
  FUNCTION getRefs (tabName TabNameType) RETURN RefsList;

  -- Возвращает сгруппированный словарь списков ограничений
  -- по имени главной/подчинённой ('by main'/'by ref') таблицы.
  -- groupRefs :: [RefRecord] -> String -> {String -> [RefRecord]}
  FUNCTION groupRefs (refs RefsList, byTab VARCHAR2 := 'by main') RETURN TabToRefsMap;

  -- Конкатенирует список строк через разделитель.
  -- joinStrings(['a', 'b', 'c', 'd'], ', ') -> 'a, b, c, d'
  -- joinStrings :: ([String], String) -> String
  FUNCTION joinStrings (strings ColsList,    joiner VARCHAR2) RETURN VARCHAR2;
  FUNCTION joinStrings (strings StringsList, joiner VARCHAR2) RETURN VARCHAR2;

  -- Возвращает изменённый список строк, где к каждой строке добавили префикс или постфикс.
  -- alterStrings(['x', 'y', 'z'], '_', '.') -> ['_x.', '_y.', '_z.']
  -- alterStrings :: [Strings] -> String -> String -> [String]
  FUNCTION alterStrings (
     strings ColsList
   , prefix  VARCHAR2 := NULL
   , postfix VARCHAR2 := NULL
  ) RETURN ColsList;

  -- Возвращает название таблицы для его использования в SQL-запросе.
  -- getSQLTableName('Employees') -> 'EMPLOYEES'
  -- getSQLTableName('"emps!"') -> 'emps!'
  -- getSQLTableName :: String -> String
  FUNCTION getSQLTableName (tabName TabNameType) RETURN TabNameType;
END UCpkg;
/
SHOW ERRORS;


-- Тело пакета для каскадного обновления (Update Cascade package).
CREATE OR REPLACE PACKAGE BODY UCpkg IS

  -- Перед каждым изменением (ALTER) таблицы нужно сохранить
  -- все её ограничения, чтобы накладывать триггеры лишь на новые ограничения.
  savedRefs RefsList := RefsList();

  -- Создаёт триггер для главной таблицы mainTab
  -- (в процедуре предполагается, что все mainTab и refTab равны,
  -- причём refTab ссылаются на mainTab).
  PROCEDURE createTrigger (refs RefsList) IS
    mainTab TabNameType := refs(1).mainTab;
     refTab TabNameType := refs(1).refTab;
    mainCols ColsList := ColsList();
     refCols ColsList := ColsList();
    triggerName TriggNameType := 'UC_'|| SUBSTR(mainTab, 1, 10) ||'_'|| SUBSTR(refTab, 1, 10);
    triggerText VARCHAR2(16384); -- текст триггера для EXECUTE IMMEDIATE
    mainColsListed VARCHAR2(256); -- имена столбцов главной таблицы через запятую

  BEGIN
    DBMS_OUTPUT.PUT_LINE('Creating trigger '|| triggerName);

    FOR r IN 1..refs.COUNT LOOP
      mainCols := mainCols MULTISET UNION DISTINCT refs(r).mainCols;
      refCols  := refCols  MULTISET UNION DISTINCT refs(r).refCols;
    END LOOP;

    mainColsListed := joinStrings(mainCols, ', ');

    DECLARE
      whenClause  VARCHAR2(1024);
      setClause   VARCHAR2(1024);
      whereClause VARCHAR2(1024);
      regularWhenClause  VARCHAR2(1024);
      regularSetClause   VARCHAR2(1024);
      regularWhereClause VARCHAR2(1024);

      setNull          VARCHAR2(1024);
      ifClause         VARCHAR2(1024);
      changeCollection VARCHAR2(1024);
      nullExpression   VARCHAR2(1024);
      updateExpression VARCHAR2(1024);

      equalStatements ColsList    := ColsList();
      ifConditions    ColsList    := ColsList();
      ifBlocks        StringsList := StringsList();

      whenCols   ColsList := mainCols;
      setCols    ColsList := mainCols;
      whereCols  ColsList := mainCols;
      nullCols   ColsList := mainCols;

      regularWhenCols  ColsList := mainCols;
      regularSetCols   ColsList := mainCols;
      regularWhereCols ColsList := mainCols;
    BEGIN
      FOR i IN 1..mainCols.COUNT LOOP
        regularWhenCols(i)  := 'OLD.'|| mainCols(i) ||' != NEW.'|| mainCols(i);
        regularSetCols(i)   := refCols(i) ||' = :NEW.'|| mainCols(i);
        regularWhereCols(i) := refCols(i) ||' = :OLD.'|| mainCols(i);

        nullCols(i)  := refCols(i) ||' = NULL';
        whenCols(i)  := ':OLD.'|| mainCols(i) ||' != :NEW.'|| mainCols(i);
        setCols(i)   := refCols(i) ||' = tabRows(i).'|| refCols(i);
        whereCols(i) := 'tabIDs(i) = ROWID';
      END LOOP;
      regularWhenClause  := joinStrings(regularWhenCols  , ' OR ' );
      regularSetClause   := joinStrings(regularSetCols   , ', '   );
      regularWhereClause := joinStrings(regularWhereCols , ' AND ');

      setNull     := joinStrings(nullCols  , ', ' );
      whenClause  := joinStrings(whenCols  , ' OR ' );
      setClause   := joinStrings(setCols   , ', '   );
      whereClause := joinStrings(whereCols , ' AND ');

      IF mainTab = refTab THEN
        nullExpression := 'UPDATE '|| mainTab ||' SET '|| setNull ||';';
        updateExpression := NULL;
      ELSE
        nullExpression := NULL;
        updateExpression := '
          UPDATE '|| refTab ||'
          SET '|| regularSetClause ||'
          WHERE '|| regularWhereClause ||';
        ';
      END IF;

      FOR i IN 1..refs.COUNT LOOP
        equalStatements.DELETE;
        ifConditions.DELETE;
        FOR j IN 1..refs(i).mainCols.COUNT LOOP
          equalStatements.EXTEND;
          equalStatements(j)
            := 'tabRows(i).'|| refs(i).refCols(j) ||' := :NEW.'|| refs(i).mainCols(j) ||';';

          ifConditions.EXTEND;
          ifConditions(j)
            := 'tabRows(i).'|| refs(i).refCols(j) ||' = :OLD.'|| refs(i).mainCols(j);
        END LOOP;

        ifBlocks.EXTEND;
        ifBlocks(i) := 'IF '|| joinStrings(ifConditions, ' AND ') ||' AND NOT changed(i)'
          ||' THEN '|| joinStrings(equalStatements, ' ') ||' changed(i) := TRUE; END IF;';
      END LOOP;

      ifClause := joinStrings(ifBlocks, ' ');

      triggerText := '
        CREATE OR REPLACE TRIGGER '|| triggerName ||'
        FOR UPDATE OF '|| mainColsListed ||' ON '|| mainTab ||'
        COMPOUND TRIGGER

          TYPE TabRowsList IS TABLE OF '|| refTab ||'%ROWTYPE;
          TYPE ROWIDList   IS TABLE OF ROWID;
          TYPE BoolList    IS TABLE OF BOOLEAN;
          tabRows TabRowsList := TabRowsList();
          tabIDs  ROWIDList   := ROWIDList();
          changed BoolList    := BoolList();

          BEFORE STATEMENT IS
          BEGIN
            SELECT *     BULK COLLECT INTO tabRows FROM '|| refTab ||';
            SELECT ROWID BULK COLLECT INTO tabIDs  FROM '|| refTab ||';
            changed.EXTEND(tabRows.COUNT);
            FOR i IN 1..changed.COUNT LOOP
              changed(i) := FALSE;
            END LOOP;

            '|| nullExpression ||'
          END BEFORE STATEMENT;
          
          BEFORE EACH ROW IS
          BEGIN
            IF '|| whenClause ||' THEN
              '|| updateExpression ||'
              FOR i IN 1..tabRows.COUNT LOOP
                '|| ifClause ||'
              END LOOP;
            END IF;
          END BEFORE EACH ROW;

          AFTER STATEMENT IS
          BEGIN
            FORALL i IN 1..tabRows.COUNT
              UPDATE '|| refTab ||'
              SET '|| setClause ||'
              WHERE tabIDs(i) = ROWID;
          END AFTER STATEMENT;

        END '|| triggerName ||';
      ';

      DBMS_OUTPUT.PUT_LINE('-- Trigger''s code: ' || triggerText);
      EXECUTE IMMEDIATE triggerText;
      DBMS_OUTPUT.PUT_LINE('Created trigger '|| triggerName);
    END;
    INSERT INTO "_UC-constraints" (Main_Table, Ref_Table, Constraint_Name)
    VALUES                        (mainTab   , refTab   , refs(1).conName);
    DBMS_OUTPUT.PUT_LINE('Inserted values into "_UC-constraints"');
    EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL;
  END;

  PROCEDURE processRefs (refs TabToRefsMap) IS
    mainRefsMap TabToRefsMap := refs;
     refRefsMap TabToRefsMap;  
    mainRefs RefsList;  
     refRefs RefsList;
    mainTab TabNameType := mainRefsMap.FIRST;
     refTab TabNameType;

    regularRefs   RefsList := RefsList(); -- Список обычных (нерекурсивных) ссылок.
    recursiveRefs RefsList := RefsList(); -- Список рекурсивных ссылок.
  BEGIN
    DBMS_OUTPUT.PUT_LINE('processing '|| refs.COUNT ||' referece(s)');
    -- Для каждой главной таблицы mainTab:
    WHILE mainTab IS NOT NULL LOOP
      mainRefs := mainRefsMap(mainTab);
      refRefsMap := groupRefs(mainRefs, 'by ref');
       

      refTab := refRefsMap.FIRST;
      regularRefs.DELETE;
      recursiveRefs.DELETE;
      -- Для каждой починённой таблицы refTab (refTab -> mainTab):
      WHILE refTab IS NOT NULL LOOP
        refRefs := refRefsMap(refTab);
        FOR r IN 1..refRefs.COUNT LOOP
          IF refRefs(r).mainTab != refRefs(r).refTab THEN
            regularRefs.EXTEND;
            regularRefs(regularRefs.LAST) := refRefs(r);
          ELSE
            recursiveRefs.EXTEND;
            recursiveRefs(recursiveRefs.LAST) := refRefs(r);
          END IF;
        END LOOP;

        refTab := refRefsMap.NEXT(refTab);
      END LOOP;
      -- Создаём триггер(ы) для mainTab,
      -- обновляющий(е) все refTab, ссылающиеся на mainTab.
      IF regularRefs.COUNT   != 0 THEN createTrigger(regularRefs);   END IF;
      IF recursiveRefs.COUNT != 0 THEN createTrigger(recursiveRefs); END IF;

      mainTab := mainRefsMap.NEXT(mainTab);
    END LOOP;
  END;

  PROCEDURE onCreateTable (tabName TabNameType) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Creating table '|| tabName);
    processRefs(groupRefs(getRefs(tabName), 'by main'));
  END;
  
  PROCEDURE beforeAlterTable (tabName TabNameType) IS
  BEGIN
    savedRefs := getRefs(tabName);
  END;

  PROCEDURE onAlterTable (tabName TabNameType) IS
    TYPE consTabRows IS TABLE OF "_UC-constraints"%ROWTYPE;
    cons consTabRows;
    refs RefsList := getRefs(tabName);
    validRefs RefsList := RefsList();
    cnt PLS_INTEGER := savedRefs.COUNT;
  BEGIN
    SELECT *
    BULK COLLECT INTO cons 
    FROM "_UC-constraints";

    FOR i IN 1..cons.COUNT LOOP
      FOR j IN 1..cnt LOOP
        IF    savedRefs.EXISTS(j)
          AND savedRefs(j).mainTab = cons(i).Main_Table
          AND savedRefs(j).refTab  = cons(i).Ref_Table
          AND savedRefs(j).conName = cons(i).Constraint_Name THEN
          savedRefs.DELETE(j);
        END IF;
      END LOOP;
    END LOOP;

    DECLARE
      i PLS_INTEGER := savedRefs.FIRST;
    BEGIN
      WHILE i IS NOT NULL LOOP
        FOR j IN 1..refs.COUNT LOOP
          IF    refs.EXISTS(j)
            AND refs(j).mainTab = savedRefs(j).mainTab
            AND refs(j).refTab  = savedRefs(j).refTab
            AND refs(j).conName = savedRefs(j).conName THEN
            refs.DELETE(j);
          END IF;
        END LOOP;
        i := savedRefs.NEXT(i);
      END LOOP;
    END;

    DECLARE
      i PLS_INTEGER := refs.FIRST;
    BEGIN
      WHILE i IS NOT NULL LOOP
        validRefs.EXTEND;
        validRefs(validRefs.LAST) := refs(i);
        i := refs.NEXT(i);
      END LOOP;
    END;

    processRefs(groupRefs(validRefs, 'by main'));
  END;

  FUNCTION getRefs (tabName TabNameType) RETURN RefsList IS
    TYPE queryRecord IS RECORD (
        Main_Table TabNameType -- :: String
      , Main_Con   ConNameType -- :: String
      , Main_Col   ColNameType -- :: String
      , Ref_Table  TabNameType -- :: String
      , Ref_Col    ColNameType -- :: String
    );
    TYPE rowsList IS TABLE OF queryRecord;
    queryResult rowsList := rowsList();
    sqlTabName TabNameType := getSQLTableName(tabName);
    result RefsList := RefsList();
  BEGIN
    -- Берём данные о ссылках таблицы на другие таблицы из словарей.
    SELECT R.Table_Name      AS Main_Table
         , L.Constraint_Name AS Main_Con
         , R.Column_Name     AS Main_Col
         , L.Table_Name      AS Ref_Table
         , L.Column_Name     AS Ref_Col
    BULK COLLECT INTO queryResult
    FROM   Constraints_View L
      JOIN Constraints_View R
        ON  L.Table_Name = 'PEOPLE'
        AND L.R_Constraint_Name = R.Constraint_Name
        AND L.Constraint_Type = 'R'
        AND L.Position = R.Position
        AND L.Status = 'ENABLED'
    ORDER BY L.Constraint_Name;

    -- Заполняем result.
    DECLARE
      currentCon ConNameType;
      currRef RefRecord;
    BEGIN
      FOR i IN 1..queryResult.COUNT LOOP
        IF currentCon IS NULL OR currentCon != queryResult(i).Main_Con THEN
          currentCon := queryResult(i).Main_Con;
          result.EXTEND;
          result(result.LAST) := currRef;
          result(result.LAST).conName := queryResult(i).Main_Con;
          result(result.LAST).mainTab := queryResult(i).Main_Table;
          result(result.LAST).refTab := queryResult(i).Ref_Table;
        END IF;
        result(result.LAST).mainCols.EXTEND;
        result(result.LAST).refCols.EXTEND;
        result(result.LAST).mainCols(result(result.LAST).mainCols.LAST) := queryResult(i).Main_Col;
        result(result.LAST).refCols(result(result.LAST).refCols.LAST)   := queryResult(i).Ref_Col;
      END LOOP;
    END;

    RETURN result;
  END;

  FUNCTION groupRefs (refs RefsList, byTab VARCHAR2 := 'by main') RETURN TabToRefsMap IS
    result TabToRefsMap;
    tab TabNameType;
    main BOOLEAN := byTab = 'by main';
  BEGIN
    FOR r IN 1..refs.COUNT LOOP
      tab := CASE WHEN main THEN refs(r).mainTab ELSE refs(r).refTab END;
      IF NOT result.EXISTS(tab) THEN
        result(tab) := RefsList();
      END IF;
      result(tab).EXTEND;
      result(tab)(result(tab).LAST) := refs(r);
    END LOOP;
    RETURN result;
  END;

  FUNCTION getSQLTableName (tabName TabNameType) RETURN TabNameType IS
  BEGIN
    IF SUBSTR(tabName, 1, 1) = '"'
    THEN RETURN REGEXP_SUBSTR(tabName, '[^"]+');
    ELSE RETURN UPPER(tabName);
    END IF;
  END;

  FUNCTION joinStrings (strings ColsList, joiner VARCHAR2) RETURN VARCHAR2 IS
    result VARCHAR2(4096);
  BEGIN
    IF strings.COUNT = 0 THEN RETURN NULL; END IF;
    FOR i IN 1..(strings.COUNT - 1) LOOP
      result := result || strings(i) || joiner;
    END LOOP;
    RETURN result || strings(strings.LAST);
  END;
  FUNCTION joinStrings (strings StringsList, joiner VARCHAR2) RETURN VARCHAR2 IS
    result VARCHAR2(16384);
  BEGIN
    IF strings.COUNT = 0 THEN RETURN NULL; END IF;
    FOR i IN 1..(strings.COUNT - 1) LOOP
      result := result || strings(i) || joiner;
    END LOOP;
    RETURN result || strings(strings.LAST);
  END;

  FUNCTION alterStrings (
     strings ColsList
   , prefix  VARCHAR2 := NULL
   , postfix VARCHAR2 := NULL
  ) RETURN ColsList IS
    result ColsList := strings;
  BEGIN
    FOR i IN 1..result.COUNT LOOP
      result(i) := prefix || result(i) || postfix;
    END LOOP;
    RETURN result;
  END;

END UCpkg;
/
SHOW ERRORS;


-- Триггер на создание (CREATE) таблицы в схеме.
CREATE OR REPLACE TRIGGER UC_After_Create
AFTER CREATE ON SCHEMA
WHEN (ORA_DICT_OBJ_TYPE = 'TABLE')
BEGIN
  DBMS_OUTPUT.PUT_LINE('Fired the trigger [AFTER CREATE]');
  UCpkg.onCreateTable(ORA_DICT_OBJ_NAME);
END;
/
SHOW ERRORS;


-- Триггер перед изменением (ALTER) таблицы в схеме.
CREATE OR REPLACE TRIGGER UC_Before_Alter
BEFORE ALTER ON SCHEMA
WHEN (ORA_DICT_OBJ_TYPE = 'TABLE')
BEGIN
  DBMS_OUTPUT.PUT_LINE('Fired the trigger [BEFORE ALTER]');
  UCpkg.beforeAlterTable(ORA_DICT_OBJ_NAME);
END;
/
SHOW ERRORS;
-- Триггер на изменение (ALTER) таблицы в схеме.
CREATE OR REPLACE TRIGGER UC_After_Alter
AFTER ALTER ON SCHEMA
WHEN (ORA_DICT_OBJ_TYPE = 'TABLE')
BEGIN
  DBMS_OUTPUT.PUT_LINE('Fired the trigger [AFTER ALTER]');
  UCpkg.onAlterTable(ORA_DICT_OBJ_NAME);
END;
/
SHOW ERRORS;