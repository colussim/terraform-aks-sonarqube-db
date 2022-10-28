create database sonarqube9
go
ALTER DATABASE sonarqube9 COLLATE Latin1_General_CS_AS;
go
CREATE LOGIN sonarqube WITH PASSWORD = 'sonarqube20@';
go
use sonarqube9;
go
create user sonarqube for login sonarqube;
go
GRANT SELECT, INSERT, UPDATE, DELETE, ALTER,CONTROL ON DATABASE::sonarqube9 to sonarqube;
go
