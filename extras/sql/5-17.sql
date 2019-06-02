DROP TRIGGER UC_After_Create;
DROP TRIGGER UC_After_Drop;
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
   Main_Table VARCHAR2(128)
 , Ref_Table  VARCHAR2(128)
 , Main_Col   VARCHAR2(128)
 , Ref_Col    VARCHAR2(128)
 , Ref_Num    NUMBER(2)
 , PRIMARY KEY (Main_Table, Ref_Table, Main_Col, Ref_Col, Ref_Num)
);


-- Пакет для организации каскадного обновления (Update Cascade package).
CREATE OR REPLACE PACKAGE UCpkg AUTHID CURRENT_USER IS
  -- Типы пакета.
  SUBTYPE TabNameType   IS USER_TABLES.Table_Name%TYPE;           -- :: String
  SUBTYPE ColNameType   IS USER_TAB_COLUMNS.Column_Name%TYPE;     -- :: String
  SUBTYPE ConNameType   IS USER_CONSTRAINTS.Constraint_Name%TYPE; -- :: String
  SUBTYPE TriggNameType IS USER_OBJECTS.Object_Name%TYPE;         -- :: String
  TYPE StringsList IS TABLE OF VARCHAR2(1024); -- :: [String]
  TYPE RefRecord IS RECORD ( -- :: RefRecord
     mainCols StringsList := StringsList() -- :: [String]
   , refCols  StringsList := StringsList() -- :: [String]
  );
  TYPE RefsList IS TABLE OF RefRecord; -- :: [RefRecord]
  TYPE RelationRecord IS RECORD ( -- :: RelationRecord
     mainTab TabNameType            -- :: String
   , refTab  TabNameType            -- :: String
   , refs    RefsList := RefsList() -- :: [RefRecord]
  );
  TYPE RelationsList IS TABLE OF RelationRecord; -- :: [RelationRecord]
  TYPE queryRecord IS RECORD ( -- Запись, которую получаем при запросе к ограничениям.
      Main_Table VARCHAR(1024) -- :: String
    , Ref_Table  VARCHAR(1024) -- :: String
    , Main_Cols  VARCHAR(1024) -- :: String
    , Ref_Cols   VARCHAR(1024) -- :: String
  );
  TYPE rowsList IS TABLE OF queryRecord; -- :: [queryRecord]

  -- Процедура, обрабатывающая создание (CREATE) таблицы.
  PROCEDURE onCreateTable (tabName TabNameType);
  -- Процедура, разбирающая ALTER выражение.
  PROCEDURE parse (statement VARCHAR2);

  -- Возвращает список таблиц со столбцами, от которых tabName зависит по FK.
  -- getRelations :: String -> [RefRecord]
  FUNCTION getRelations (tabName TabNameType) RETURN RelationsList;

  -- Возвращает структурированную версию запроса (превращает его в RelationsList)
  -- structureConstraints :: [queryRecord] -> [RelationRecord]
  FUNCTION structureConstraints (queryResult rowsList) RETURN RelationsList;

  -- String2ListOfObjects('A, B, C') -> ['A', 'B', 'C']
  -- String2ListOfObjects :: String -> [String]
  FUNCTION String2ListOfObjects (string VARCHAR2)  RETURN StringsList;

  -- Конкатенирует список строк через разделитель.
  -- joinStrings(['a', 'b', 'c', 'd'], ', ') -> 'a, b, c, d'
  -- joinStrings :: ([String], String) -> String
  FUNCTION joinStrings (strings StringsList, joiner VARCHAR2) RETURN VARCHAR2;

  -- Возвращает название таблицы для его использования в SQL-запросе.
  -- toSQLname('Employees') -> 'EMPLOYEES'
  -- toSQLname('"emps!"') -> 'emps!'
  -- toSQLname :: String -> String
  FUNCTION toSQLname (tabName TabNameType) RETURN TabNameType;
END UCpkg;
/


-- Тело пакета для каскадного обновления (Update Cascade package).
CREATE OR REPLACE PACKAGE BODY UCpkg IS

  FAILURE_IN_FORALL EXCEPTION;  
  PRAGMA EXCEPTION_INIT (FAILURE_IN_FORALL, -24381);

  -- Регулярные выражения для обработки AFTER ALTER.
  OBJECT_RE VARCHAR2(1024) := '([[:alpha:]_[:digit:]#$]+|"[^"]+")'; -- Регулярка имени объекта
  ALTER_ADD_FK_RE  VARCHAR2(1024) -- Регулярка для вылавливания главной таблицы и столбцов
    := 'ALTER\s+TABLE\s+'|| OBJECT_RE ||'\s+ADD\s+'
    || '(CONSTRAINT\s+'|| OBJECT_RE ||'\s+)?'
    || 'FOREIGN\s+KEY\s*\(('|| OBJECT_RE ||'(,\s*'|| OBJECT_RE ||')*)\)\s*'
    || 'REFERENCES\s+'|| OBJECT_RE ||'\s*\(('|| OBJECT_RE ||'(,\s*'|| OBJECT_RE ||')*)\).*';

  -- Создаёт триггер для главной таблицы mainTab (относительно подчинённой refTab)
  PROCEDURE createTrigger (mainTab TabNameType, refTab TabNameType, refs RefsList) IS
    mainCols StringsList := StringsList();
    refCols StringsList  := StringsList();
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

      equalStatements StringsList    := StringsList();
      ifConditions    StringsList    := StringsList();
      ifBlocks        StringsList := StringsList();

      whenCols   StringsList := mainCols;
      setCols    StringsList := mainCols;
      whereCols  StringsList := mainCols;
      nullCols   StringsList := mainCols;

      regularWhenCols  StringsList := mainCols;
      regularSetCols   StringsList := mainCols;
      regularWhereCols StringsList := mainCols;
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
      -- EXECUTE IMMEDIATE triggerText;
      -- DBMS_OUTPUT.PUT_LINE('Created trigger '|| triggerName);
    END;

    DECLARE
      ref RefRecord;
    BEGIN
      FOR r IN 1..refs.COUNT LOOP
        BEGIN
          ref := refs(r);
          FORALL c IN 1..ref.mainCols.COUNT
          SAVE EXCEPTIONS
            INSERT INTO "_UC-constraints"
              (Main_Table, Ref_Table, Main_Col       , Ref_Col       , Ref_Num)
            VALUES
              (mainTab   , refTab   , ref.mainCols(c), ref.refCols(c), r      );
        EXCEPTION WHEN FAILURE_IN_FORALL THEN NULL;
        END;
      END LOOP;
    END;
  END;

  PROCEDURE onCreateTable (tabName TabNameType) IS
    relations RelationsList := getRelations(tabName);
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Creating table '|| tabName);
    FOR i IN 1..relations.COUNT LOOP
      createTrigger(relations(i).mainTab, relations(i).refTab, relations(i).refs);
    END LOOP;
  END;

  PROCEDURE parse (statement VARCHAR2) IS
  BEGIN
    IF NOT REGEXP_LIKE(statement, ALTER_ADD_FK_RE) THEN RETURN; END IF;
    DECLARE
      refTab  VARCHAR2(1024) := toSQLname(REGEXP_REPLACE(statement, ALTER_ADD_FK_RE, '\1'));
      mainTab VARCHAR2(1024) := toSQLname(REGEXP_REPLACE(statement, ALTER_ADD_FK_RE, '\8'));
      refColsString  VARCHAR2(1024) := REGEXP_REPLACE(statement, ALTER_ADD_FK_RE, '\4');
      mainColsString VARCHAR2(1024) := REGEXP_REPLACE(statement, ALTER_ADD_FK_RE, '\9');
      mainCols StringsList := String2ListOfObjects(refColsString);
      refCols  StringsList := String2ListOfObjects(mainColsString);

      queryResult rowsList := rowsList();
      relations RelationsList;
    BEGIN
      FOR i IN 1..mainCols.COUNT LOOP
        mainCols(i) := toSQLname(mainCols(i));
      END LOOP;
      FOR i IN 1..refCols.COUNT LOOP
        refCols(i) := toSQLname(refCols(i));
      END LOOP;

      SELECT Main_Table
           , Ref_Table
           , LISTAGG(Main_Col, ', ') WITHIN GROUP (ORDER BY Main_Col, Ref_Col) AS Main_Cols
           , LISTAGG(Ref_Col , ', ') WITHIN GROUP (ORDER BY Main_Col, Ref_Col) AS Ref_Cols
      BULK COLLECT INTO queryResult
      FROM "_UC-constraints"
      WHERE Ref_Table = refTab
      GROUP BY Main_Table, Ref_Table, Ref_Num
      ORDER BY Main_Table, Ref_Table;

      relations := structureConstraints(queryResult);

      DECLARE
        added BOOLEAN := FALSE;
        indx PLS_INTEGER;
      BEGIN
        FOR r IN 1..relations.COUNT LOOP
          CONTINUE WHEN mainTab != relations(r).mainTab
                     OR refTab  != relations(r).refTab;
          relations(r).refs.EXTEND;
          relations(r).refs(relations(r).refs.LAST).mainCols := mainCols;
          relations(r).refs(relations(r).refs.LAST).refCols  := refCols;
          added := TRUE;
          EXIT;
        END LOOP;

        IF NOT added THEN
          relations.EXTEND;
          indx := relations.LAST;
          relations(indx).mainTab := mainTab;
          relations(indx).refTab  := refTab;
          relations(indx).refs := RefsList();
          relations(indx).refs.EXTEND;
          relations(indx).refs(relations(indx).refs.LAST).mainCols := mainCols;
          relations(indx).refs(relations(indx).refs.LAST).refCols  := refCols;
        END IF;
      END;

      FOR i IN 1..relations.COUNT LOOP
        createTrigger(relations(i).mainTab, relations(i).refTab, relations(i).refs);
      END LOOP;
    END;
  END;

  FUNCTION getRelations (tabName TabNameType) RETURN RelationsList IS
    queryResult rowsList := rowsList();
    sqlTabName TabNameType := toSQLname(tabName);
  BEGIN
    -- Берём данные о ссылках таблицы на другие таблицы из словарей.
    SELECT R.Table_Name AS Main_Table
         , L.Table_Name AS Ref_Table
         , LISTAGG(R.Column_Name, ', ') WITHIN GROUP (ORDER BY L.Position) AS Main_Cols
         , LISTAGG(L.Column_Name, ', ') WITHIN GROUP (ORDER BY L.Position) AS Ref_Cols
    BULK COLLECT INTO queryResult
    FROM   Constraints_View L
      JOIN Constraints_View R
        ON  L.Table_Name = sqlTabName
        AND L.R_Constraint_Name = R.Constraint_Name
        AND L.Constraint_Type = 'R'
        AND L.Position = R.Position
        AND L.Status = 'ENABLED'
    GROUP BY R.Table_Name, L.Table_Name, L.Constraint_Name
    ORDER BY R.Table_Name, L.Table_Name;

    DBMS_OUTPUT.PUT_LINE('sqlTabName = '|| sqlTabName);
    DBMS_OUTPUT.PUT_LINE('queryResult.COUNT = '|| queryResult.COUNT);

    RETURN structureConstraints(queryResult);
  END;

  FUNCTION structureConstraints (queryResult rowsList) RETURN RelationsList IS
    result RelationsList := RelationsList();
    currRelation RelationRecord;
    currRef      RefRecord;
    currRefs RefsList := RefsList();
    r queryRecord; -- row
  BEGIN
    FOR i IN 1..queryResult.COUNT LOOP
      r := queryResult(i);

      IF currRelation.mainTab IS NOT NULL AND (
           currRelation.mainTab != r.Main_Table 
        OR currRelation.refTab  != r.Ref_Table
      )
      THEN
        result.EXTEND;
        result(result.LAST) := currRelation;

        currRelation.mainTab := r.Main_Table;
        currRelation.refTab  := r.Ref_Table;
        currRelation.refs.DELETE;
      END IF;

      currRef.mainCols := String2ListOfObjects(r.Main_Cols);
      currRef.refCols  := String2ListOfObjects(r.Ref_Cols);
      currRelation.refs.EXTEND;
      currRelation.refs(currRelation.refs.LAST) := currRef;

      IF currRelation.mainTab IS NULL THEN
        currRelation.mainTab := r.Main_Table;
        currRelation.refTab  := r.Ref_Table;
      END IF;
    END LOOP;

    IF currRelation.refs.COUNT > 0 THEN
      result.EXTEND;
      result(result.LAST) := currRelation;
    END IF;

    RETURN result;
  END;

  FUNCTION String2ListOfObjects (string VARCHAR2)  RETURN StringsList IS
    result StringsList := StringsList();
    n PLS_INTEGER := REGEXP_COUNT(string, OBJECT_RE);
  BEGIN
    result.EXTEND(n);
    FOR i IN 1..n LOOP
      result(i) := REGEXP_SUBSTR(string, OBJECT_RE, 1, i);
    END LOOP;
    RETURN result;
  END;

  FUNCTION toSQLname (tabName TabNameType) RETURN TabNameType IS
  BEGIN
    IF SUBSTR(tabName, 1, 1) = '"'
    THEN RETURN REGEXP_SUBSTR(tabName, '[^"]+');
    ELSE RETURN UPPER(tabName);
    END IF;
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

END UCpkg;
/


-- Триггер на создание (CREATE) таблицы в схеме.
CREATE OR REPLACE TRIGGER UC_After_Create
AFTER CREATE ON SCHEMA
WHEN (ORA_DICT_OBJ_TYPE = 'TABLE')
BEGIN
  DBMS_OUTPUT.PUT_LINE('Fired the trigger [AFTER CREATE] on '|| ORA_DICT_OBJ_NAME);
  UCpkg.onCreateTable(ORA_DICT_OBJ_NAME);
END;
/

-- Триггер на изменение (ALTER) таблицы в схеме.
CREATE OR REPLACE TRIGGER UC_After_Alter
AFTER ALTER ON SCHEMA
WHEN (ORA_DICT_OBJ_TYPE = 'TABLE')
DECLARE
  sqlText ORA_NAME_LIST_T;
  statement varchar2(1024);
  n PLS_INTEGER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Fired the trigger [AFTER ALTER] on '|| ORA_DICT_OBJ_NAME);
  n := ORA_SQL_TXT(sqlText);
  FOR i in 1..n LOOP
    statement := statement || sqlText(i);
  END LOOP;

  UCpkg.parse(statement);
END;
/
