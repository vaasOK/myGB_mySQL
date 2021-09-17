/*
 * 
*/

USE test;

/*
1. 
   Составьте список пользователей users, 
	 которые осуществили хотя бы один заказ orders в интернет магазине.

*/
/*
SELECT id, RAND() AS rand_id FROM users ORDER BY rand_id LIMIT 6;

INSERT INTO orders (user_id)
VALUES
    (SELECT id FROM users ORDER BY RAND() LIMIT 1;)
  , (SELECT id FROM users ORDER BY RAND() LIMIT 1;) 
;
*/


INSERT INTO orders
    (user_id)
VALUES
    (4), (2), (4), (6), (4), (2), (2), (2), (5), (6), (2), (4), (5), (2), (6), (2), (2), (6), (5), (5), (4), (2), (5), (6), (2), (4), (2)
;


--  Вложенный SELECT 

SELECT name
  FROM users u 
 WHERE id IN (
	  SELECT user_id 
	    FROM orders
	GROUP BY user_id
	)
;

-- JOIN

   SELECT u.name
     FROM users u  
     JOIN orders o
    WHERE u.id = o.user_id
 GROUP BY u.name 
;


/*

2. 
   Выведите список товаров products и разделов catalogs, 
	 который соответствует товару.
*/

--  Вложенный SELECT 

SELECT  p.name
       , (SELECT c.name 
	        FROM catalogs c 
	       WHERE c.id = p.catalog_id ) AS catalog  
  FROM products p
;

-- JOIN 

SELECT p.name prod_name 
     , c.name cat_name
  FROM products p
  JOIN catalogs c 
 WHERE c.id = p.catalog_id 
;

/*
3. (по желанию) 
   Пусть имеется 
	   таблица рейсов flights (id, from, to) 
	   и таблица городов cities (label, name). 
	   
	   Поля from, to и label содержат английские названия городов, 
	   поле name — русское. 
   
   Выведите список рейсов flights с русскими названиями городов.
*/
DROP TABLE IF EXISTS `flights`
;
CREATE TABLE `flights`(
    id SERIAL PRIMARY KEY
  , `from` VARCHAR(100) NOT NULL
  , `to` VARCHAR(100) NOT NULL
);
INSERT INTO `flights`
            (`from`, `to`)
     VALUES
            ('moscow', 'omsk')
          , ('novgorod', 'kazan') 
          , ('irkutsk', 'moscow') 
          , ('omsk', 'irkutsk') 
          , ('moscow', 'kazan') 
;

DROP TABLE IF EXISTS `cities`
;
CREATE TABLE `cities`(
    `label` VARCHAR(100) NOT NULL
  , `name` VARCHAR(100) NOT NULL UNIQUE
);
INSERT INTO `cities`
    (`label`, `name`)
VALUES
    ('moscow', 'Москва')
  , ('irkutsk', 'Иркутск') 
  , ('novgorod', 'Ногород') 
  , ('moscow', 'Казань') 
  , ('omsk', 'Омск') 
;


--  Вложенный SELECT 

SELECT 
       f.id AS "номер рейса"
     , (SELECT 
               name
          FROM 
               cities AS c1
         WHERE 
               c1.label = f.`from`) AS "откуда"
     , (SELECT 
               name
          FROM 
               cities AS c2
         WHERE 
               c2.label = f.`to`) AS "куда" 
  FROM 
       flights AS f 
;

-- JOIN 

  SELECT 
         f.id "номер рейса"
       , c1.name "откуда"
       , c2.name "куда"
	FROM 
	     flights f
	JOIN
	     cities c1
	JOIN
	     cities c2 
   WHERE 
	     f.`from` = c1.label 
     AND 
	     f.`to` = c2.label 
ORDER BY
         f.id 
       ;
