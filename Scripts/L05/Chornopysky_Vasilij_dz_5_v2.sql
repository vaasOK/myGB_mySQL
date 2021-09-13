/*
 * https://docs.google.com/document/d/1spUZwRiyKVwo7tB4X9NVUkPXvLoFc8UQ53LAkpPcURo/edit#
Практическое задание по теме “Операторы, фильтрация, сортировка и ограничение”
*/

USE test;

/*
1. Пусть в таблице users поля created_at и updated_at оказались незаполненными. 
	Заполните их текущими датой и временем.
*/

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


/*
 * да, после просмотра видеоразбора понял, что можно было обойтись без временных столбцов
 * 
 * (ошибочно считал, что преобразование типа данных у столбца с заполненными значениями может привести к потере этих значений.)
 */


ALTER TABLE users 
ADD tmp_date DATETIME
;
UPDATE users 
  , SET tmp_date = STR_TO_DATE(created_at, "%d.%m.%Y %k:%i")
--   , SET tmp_date = STR_TO_DATE(updated_at, "%d.%m.%Y %k:%i")
;
UPDATE users 
	SET created_at = NULL 
;
ALTER TABLE users
MODIFY COLUMN created_at DATETIME
;
UPDATE users 
	SET created_at = tmp_date
;
UPDATE users 
  , SET tmp_date = STR_TO_DATE(updated_at, "%d.%m.%Y %k:%i")
;
UPDATE users 
	SET updated_at = NULL 
;
ALTER TABLE users
MODIFY COLUMN updated_at DATETIME
;
UPDATE users 
	SET updated_at = tmp_date

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
 * "Подсмотрел" решение в видеоразборе, но сделал "по своему" 
 * как по мне, условие для функции IF() у меня несколько понятнее... 
 */

DROP TABLE IF EXISTS `storehouses_products`;
CREATE TABLE storehouses_products (
    id SERIAL PRIMARY KEY COMMENT 'id записи о товаре'
  , product_id INT UNSIGNED COMMENT 'id товара'
  , value INT UNSIGNED COMMENT 'количество товара на складе'
) COMMENT 'модель таблицы складских запасов';

INSERT INTO storehouses_products 
    (product_id, value )
VALUES
    (5754, 0)
  , (2345, 2500)
  , (4345, 0)
  , (4523, 30)
  , (3442, 500)
  , (1234, 1)
;

SELECT *
FROM storehouses_products
ORDER BY IF(value=0, 1, 0), value  
;


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
USE shop
;

SELECT * 
  FROM  catalogs
  WHERE id in (5, 1, 2)
  ORDER BY FIELD(id, 5, 1, 2)
;
/*
USE sakila
;
SELECT * 
  FROM film_actor
  WHERE actor_id in (5, 1, 2)
  ORDER BY FIELD(actor_id, 5, 1, 2)
 ;
*/

/*
Практическое задание теме “Агрегация данных”

1. Подсчитайте средний возраст пользователей в таблице users
*/
USE shop 
;
SELECT 	
AVG(TIMESTAMPDIFF(YEAR, birthday_at, NOW())) AS AVG_age 
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
		) AS week_day
  , COUNT(*) AS quantity 
FROM users u 
GROUP BY week_day
ORDER BY quantity
;


/*
3. (по желанию) Подсчитайте произведение чисел в столбце таблицы
*/

/*
 * Решение "подсмотрел" в видеоразборе ДЗ
 * Своё решение делал через все логарифмы )
 */

USE shop
;

-- SELECT id, LOG10(id), SUM(LOG10(id)) 
-- SELECT SUM(LOG10(id))
SELECT 
    POW (10, SUM(LOG10(id)))AS base_10_mult
  , ROUND (POW(10, SUM(LOG10(id)))) AS round_base_10_mult
  , POW(2, SUM(LOG(2, id)))AS base_2_mult
  , ROUND(POW(2, SUM(LOG2(id)))) AS round_base_2_mult
  , EXP(SUM(LN(id)))AS base_e_mult
  , ROUND(EXP(SUM(LN(id)))) AS round_base_10_mult
FROM catalogs c 
;