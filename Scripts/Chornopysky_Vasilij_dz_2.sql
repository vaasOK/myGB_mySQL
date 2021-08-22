DROP DATABASE IF EXISTS example;
CREATE DATABASE example;
USE example;
CREATE TABLE `users` ( id SERIAL,name VARCHAR(50) );
DROP DATABASE IF EXISTS sample;
CREATE DATABASE sample;
USE sample;

SYSTEM mysqldump example > example-dump.sql ;

SHOW TABLES;

SOURCE example-dump.sql ;

SHOW TABLES;
