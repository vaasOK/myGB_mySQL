/*
* Задание 1
* Установите СУБД MySQL. 
* Создайте в домашней директории файл .my.cnf, 
* 	задав в нем логин и пароль, 
* 	который указывался при установке.
*/

/*
* vas@gb-db:~$ mysql -p
* Enter password:
* Welcome to the MySQL monitor.  Commands end with ; or \g.
* Your MySQL connection id is 15
* Server version: 8.0.26-0ubuntu0.20.04.2 (Ubuntu)
* 
* Copyright (c) 2000, 2021, Oracle and/or its affiliates.
* 
* Oracle is a registered trademark of Oracle Corporation and/or its
* affiliates. Other names may be trademarks of their respective
* owners.
* 
* Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
* 
* mysql>
* mysql>
* */
-- \! pwd
/*
/home/vas
 */

/*
\! echo "[client]" >> ~/.my.cnf
\! echo "user=vas" >> ~/.my.cnf
\! echo "password=xxxxxx" >> ~/.my.cnf
\! echo "" >> ~/.my.cnf
\! cat ~/.my.cnf
*/

/*
[client]
user=vas
password=xxxxxx
*/

-- exit

/*
Bye
vas@gb-db:~$ mysql
* Welcome to the MySQL monitor.  Commands end with ; or \g.
* Your MySQL connection id is 16
* Server version: 8.0.26-0ubuntu0.20.04.2 (Ubuntu)
* 
* Copyright (c) 2000, 2021, Oracle and/or its affiliates.
* 
* Oracle is a registered trademark of Oracle Corporation and/or its
* affiliates. Other names may be trademarks of their respective
* owners.
* 
* Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
* 
* mysql> 
* mysql>
*/

/*
* Задание 2
* 
* Создайте базу данных example, 
* 	разместите в ней таблицу users, 
* 		состоящую из двух столбцов, 
* 			числового id и строкового name.
*
*/
DROP DATABASE IF EXISTS example;
CREATE DATABASE example;
USE example;
CREATE TABLE `users` (
	id BIGINT UNSIGNED NOT NULL UNIQUE,
	name VARCHAR(50) 
);
/*
* 
* * Задание 3
*  
* Создайте дамп базы данных example из предыдущего задания, 
* 	разверните содержимое дампа в новую базу данных sample.
* 
* 
*/
SYSTEM ls ~;
SYSTEM mysqldump example > ~/example.SQL ; 

DROP DATABASE IF EXISTS sample;
CREATE DATABASE sample;
USE sample;

SHOW TABLES;

SYSTEM mysql sample < ~/example.SQL ;

SHOW TABLES;
/*
* 
* 
*  Задание 4 (по желанию) 
* 		Ознакомьтесь более подробно с документацией утилиты mysqldump. 
* 		Создайте дамп единственной таблицы help_keyword базы данных mysql. 
* 			Причем добейтесь того, чтобы дамп содержал только первые 100 строк таблицы.
* 
* 
*/
/*

mysqldump mysql --where='1 limit 100' help_keyword > ~/mysql_help_kw.sql


*/




