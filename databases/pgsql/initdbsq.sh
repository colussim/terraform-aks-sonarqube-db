psql -v ON_ERROR_STOP=1 --username "postgres" --dbname "postgres" <<-EOSQL
CREATE ROLE sonarqube WITH LOGIN PASSWORD 'sonarqube';
CREATE DATABASE sonarqube9 WITH ENCODING 'UTF8' OWNER sonarqube TEMPLATE=template0;
GRANT ALL PRIVILEGES ON DATABASE sonarqube9 TO sonarqube;"
EOSQL
