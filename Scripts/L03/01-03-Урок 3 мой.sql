#
#
#
DROP DATABASE IF EXISTS vk;
CREATE DATABASE vk;
USE vk;

DROP TABLE IF EXISTS users;	# строго говоря, таблицы не будет - выше удалили всь базу
CREATE TABLE users(
	id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	#id2 SERIAL, #BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE # SERIAL - псевдотип
	firstname VARCHAR(200),
	lastname VARCHAR(200) COMMENT 'фамилия...',
	email  VARCHAR(200) UNIQUE,
	password  VARCHAR(255),
	phone BIGINT UNSIGNED UNIQUE,  # =7 (900) 123-45-67  => 79 001 234 567
	INDEX (firstname, lastname)
	) COMMENT 'юзеры...';


