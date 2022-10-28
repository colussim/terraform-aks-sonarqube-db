/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Bench123Bench123 -d master -Q "
create database sonarqube9
go
CREATE LOGIN sonarqube WITH PASSWORD = 'sonarqube'
go
use sonarqube9
go
create user sonarqube for login sonarqube
go
GRANT CONTROL ON DATABASE::sonarqube9 to sonarqube
go"
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Bench123Bench123 -d master -Q "ALTER DATABASE sonarqube9 COLLATE Latin1_General_CS_AS;"