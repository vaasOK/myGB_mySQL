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
	user_id BIGINT UNSIGNED NOT NULL UNIQUE,
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
SYSTEM mysqldump example > ~/vas_example.sql 

DROP DATABASE IF EXISTS sample;
CREATE DATABASE sample;
USE sample;

SHOW TABLES;

SYSTEM mysql sample < ~/vas_example.sql ;

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



