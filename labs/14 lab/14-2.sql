CREATE OR REPLACE PROCEDURE web_employee_report IS
  paramVal OWA.VC_ARR;
BEGIN
  paramVal(1) := 1;
  OWA.INIT_CGI_ENV(paramVal);

  HTP.HTMLOPEN;
    HTP.HEADOPEN;
      HTP.TITLE('Отчёт');
      HTP.PRINT('<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" integrity="sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T" crossorigin="anonymous">'); -- подключаем Bootstrap
    HTP.HEADCLOSE;
    HTP.BODYOPEN;
      HTP.PRINT('<div class="container">');
        HTP.PRINT(
            '<h1>--- Отчёт. Влад Фурман, 33536/2 ['
          || TO_CHAR(SYSDATE, 'DD.MM.YYYY HH24:MI:SS')
          ||'] ---</h1>'
        );
        HTP.PRINT('<table class="table table-SQL table-bordered table-hover table-sm">');
          HTP.PRINT('<thead class="thead-dark"><tr><th>Emp #</th><th>First Name</th><th>Last Name</th><th>Department #</th><th>Salary</th></tr></thead>');
          HTP.PRINT('<tbody>');
            FOR queryR IN (
              SELECT *
              FROM (
                SELECT
                  Employee_ID, First_Name, Last_Name, Department_ID, Salary,
                  AVG(Salary) OVER (PARTITION BY Department_ID) AS Average
                FROM Employees
              )
              WHERE Salary > Average
              ORDER BY Employee_ID
            ) LOOP
              HTP.PRINT(
                '<tr><td>'||    queryR.Employee_ID
                ||'</td><td>'|| queryR.First_Name
                ||'</td><td>'|| queryR.Last_Name
                ||'</td><td>'|| queryR.Department_ID
                ||'</td><td>'|| queryR.Salary ||'</td></tr>'
              );
            END LOOP;
          HTP.PRINT('</tbody>');
        HTP.PRINT('</table>');

      HTP.PRINT('</div>');
    HTP.BODYCLOSE;
  HTP.HTMLCLOSE;
END;
/

SET SERVEROUTPUT ON;
BEGIN
  web_employee_report;
  OWA_UTIL.SHOWPAGE;
END;
/