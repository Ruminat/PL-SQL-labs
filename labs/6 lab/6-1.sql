DEFINE countryID = 'CA'

DECLARE
  country_record Countries%ROWTYPE;
  countryID VARCHAR2(64);
BEGIN
  countryID := '&countryID';
  
  SELECT *
  INTO country_record
  FROM Countries
  WHERE Country_ID = countryID;

  DBMS_OUTPUT.PUT_LINE(
       'Country Id: '    || countryID
    || ' Country Name: ' || country_record.Country_Name
    || ' Region: '       || country_record.Region_ID
  );
END;