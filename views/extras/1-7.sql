ACCEPT dep NUMBER PROMPT 'Введите идентификатор отдела: ';
DECLARE
  dep_name  Departments.Department_Name%TYPE;
  street    Locations.Street_Address%TYPE;
  code      Locations.Postal_Code%TYPE;
  city_name Locations.City%TYPE;
  country   Countries.Country_Name%TYPE;
BEGIN
  SELECT
    NVL(Department_Name , '?') ,
    NVL(Street_Address  , '?') ,
    NVL(Postal_Code     , '?') ,
    NVL(City            , '?') ,
    NVL(Country_Name    , '?')
  INTO dep_name, street, code, city_name, country
  FROM Departments
    LEFT JOIN Locations USING (Location_ID)
    LEFT JOIN Countries USING (Country_ID)
  WHERE Department_ID = &&dep;

  DBMS_OUTPUT.PUT_LINE('Номер отдела, название: Отдел № ' || &&dep || ', «' || dep_name || '»');
  DBMS_OUTPUT.PUT_LINE('Дом, улица: ' || street);
  DBMS_OUTPUT.PUT_LINE('Индекс, город, страна: ' || code || ', ' || city_name || ', ' || country);
END;