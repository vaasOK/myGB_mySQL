/*
 * https://docs.google.com/document/d/1spUZwRiyKVwo7tB4X9NVUkPXvLoFc8UQ53LAkpPcURo/edit#

Практическое задание по теме “Операторы, фильтрация, сортировка и ограничение”

1. Пусть в таблице users поля created_at и updated_at оказались незаполненными. 
	Заполните их текущими датой и временем.
*/

USE test;

UPDATE users 
  SET   created_at = CURRENT_TIMESTAMP,
 		updated_at = NOW()
;


/*
2. Таблица users была неудачно спроектирована. 
	Записи created_at и updated_at были заданы типом VARCHAR 
	и в них долгое время помещались значения в формате "20.10.2017 8:10". 
		Необходимо преобразовать поля к типу DATETIME, 
		сохранив введеные ранее значения.
*/

ALTER TABLE users 
ADD bad_date VARCHAR(20); 


INSERT INTO test.users
	(name, birthday_at, created_at, updated_at, bad_date)
VALUES
	  ('b_name_1', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, '20.10.2017 8:10')
	, ('b_name_2', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, '20.9.2018 8:10')
	, ('b_name_3', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, '20.11.2015 05:04')
	, ('b_name_4', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, '20.04.2011 07:10')
	, ('b_name_5', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, '20.10.2002 15:6')
;

-- SELECT STR_TO_DATE("20.10.2017 8:10", "%d.%m.%Y %k:%i");
 	
ALTER TABLE users 
ADD tmp_date DATETIME; 

UPDATE users 
	SET tmp_date = STR_TO_DATE(bad_date, "%d.%m.%Y %k:%i")
--   , SET tmp_date = STR_TO_DATE(created_at, "%d.%m.%Y %k:%i")
--   , SET tmp_date = STR_TO_DATE(updated_at, "%d.%m.%Y %k:%i")
WHERE name LIKE 'b_name%'
;

ALTER TABLE users 
DROP COLUMN  bad_date
;



UPDATE users 
	SET bad_date = NULL 
;

ALTER TABLE users
MODIFY COLUMN bad_date DATETIME
;


UPDATE users 
	SET bad_date = tmp_date
WHERE name LIKE 'b_name%'
;


ALTER TABLE users 
DROP COLUMN  tmp_date
;



	
/*
3. В таблице складских запасов storehouses_products 
	в поле value могут встречаться самые разные цифры: 
		0, если товар закончился 
		и выше нуля, если на складе имеются запасы. 
	Необходимо отсортировать записи таким образом, 
		чтобы они выводились в порядке увеличения значения value. 
		Однако, нулевые запасы должны выводиться в конце, после всех записей.
*/


/*
4. (по желанию) 
	Из таблицы users необходимо извлечь пользователей, 
		родившихся в августе и мае. 
	Месяцы заданы в виде списка английских названий ('may', 'august')
*/
USE shop
;

SELECT name,  DATE_FORMAT(birthday_at, "%M") 
	FROM users
 	WHERE DATE_FORMAT(birthday_at, "%M") IN ('may', 'august')
;

/*
5.(по желанию) 
	Из таблицы catalogs извлекаются записи при помощи запроса. 
		SELECT * FROM catalogs WHERE id IN (5, 1, 2); 
	Отсортируйте записи в порядке, заданном в списке IN.
*/


USE sakila
;
SELECT * 
  FROM film_actor
  WHERE actor_id in (5, 1, 2)
  ORDER BY FIELD(actor_id, 5, 1, 2)
 ;




/*
Практическое задание теме “Агрегация данных”

1. Подсчитайте средний возраст пользователей в таблице users
*/

USE shop 
;
SELECT 	
ROUND(AVG(TIMESTAMPDIFF(YEAR, birthday_at, NOW())), 1) AS AVG_age 
FROM users
;

/*
2. Подсчитайте количество дней рождения, 
		которые приходятся на каждый из дней недели. 
	Следует учесть, что необходимы дни недели текущего года, а не года рождения.
*/
SELECT 
	DAYNAME( 
		CONCAT( 
		    DATE_FORMAT(CURRENT_TIMESTAMP, '%Y')
		  , "-"  
		  , DATE_FORMAT(birthday_at, '%m-%d')
		)
	) AS dn
  , COUNT(*)
FROM users u 
GROUP BY dn
;


/*
3. (по желанию) Подсчитайте произведение чисел в столбце таблицы
*/



