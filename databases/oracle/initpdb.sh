#!/bin/bash

mkdir -p /opt/oracle/oradata/sonarqube9
chown -R 54321:54321 /opt/oracle/oradata/sonarqube9

echo "Create a PCB Database sonarqube9 and user : sonarqube"
sqlplus / as sysdba 2>&1 <<EOF
 CREATE USER sonarqube IDENTIFIED BY sonarqube ;
 GRANT CONNECT, RESOURCE TO sonarqube;
 GRANT SELECT ANY DICTIONARY TO sonarqube;
 GRANT  ALL PRIVILEGES  TO sonarqube CONTAINER=ALL;

CREATE PLUGGABLE DATABASE sonarqube9 ADMIN USER sonar IDENTIFIED BY sonarqube 
STORAGE (MAXSIZE 9G) 
DEFAULT TABLESPACE sonarqube 
  DATAFILE '/opt/oracle/oradata/sonarqube9/sonarqube01.dbf' SIZE 5G AUTOEXTEND ON 
  PATH_PREFIX = '/opt/oracle/oradata/sonarqube91/' 
  FILE_NAME_CONVERT = ('/opt/oracle/oradata/XE/pdbseed/','/opt/oracle/oradata/sonarqube9/');


ALTER PLUGGABLE DATABASE sonarqube9 OPEN READ WRITE;    
alter pluggable database all save state; 
EOF

echo "USE_SID_AS_SERVICE_SONARQUBE9=on" >> /opt/oracle/homes/Ora*/network/admin/listener.ora
lsnrctl reload


