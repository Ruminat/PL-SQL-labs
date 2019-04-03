ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';
WITH Edges AS (
  SELECT Acity AS From_Node, Bcity AS To_Node, Dist AS Range
  FROM Paths
),
Param (  Begin_Node , End_Node) AS (
  SELECT 'Pskov', 'Vologda' FROM dual
),
All_Edges AS (
  SELECT To_Node AS From_Node, From_Node AS To_Node, Range
  FROM Edges
  UNION
  SELECT From_Node, To_Node, Range
  FROM Edges
),
All_Paths AS (
  SELECT
    ROWNUM AS ID,
    LTRIM(SYS_CONNECT_BY_PATH(From_Node, '-'), '-')
      || '-' || To_Node AS ThePath,
    SYS_CONNECT_BY_PATH(Range, '+') AS Ranges
  FROM All_Edges
  WHERE To_Node = (SELECT End_Node FROM Param)
  START WITH From_Node = (SELECT Begin_Node FROM Param)
  CONNECT BY NOCYCLE PRIOR To_Node = From_Node
),
Paths_With_Ranges AS (
  SELECT ID, SUM(Range) AS TheSum
  FROM (
    SELECT
      ID,
      TO_NUMBER(REGEXP_SUBSTR(Ranges, '\d*\.\d+|\d+\.\d*|\d+', 1, LEVEL)) AS Range
    FROM All_Paths
    CONNECT BY LEVEL <= REGEXP_COUNT(Ranges, '\d*\.\d+|\d+\.\d*|\d+')
      AND PRIOR ID = ID AND PRIOR SYS_GUID() IS NOT NULL
  )
  GROUP BY ID
)
SELECT ThePath AS Path, TheSum AS Len
FROM (
  SELECT
    ROW_NUMBER() OVER (ORDER BY TheSum) AS Path_ID,
    ThePath, TheSum
  FROM Paths_With_Ranges JOIN All_Paths USING (ID)
)
ORDER BY 1, 2
-- WHERE Path_ID <= 3;