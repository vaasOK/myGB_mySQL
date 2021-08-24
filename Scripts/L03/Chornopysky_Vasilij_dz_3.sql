/*
 *
 *	Пока заглушка,обязуюсь до 25 августа выполнить  
 *
 *	начало такое
 *  выполнять ещё не пробовал
 *
 *
 *
 * 1. Написать крипт, 
 * 		добавляющий в БД vk, которую создали на занятии, 
 * 			3 новые таблицы (с перечнем полей, указанием индексов и внешних ключей) 
 */

DROP TABLE IF EXISTS games;
CREATE TABLE games(
	id SERIAL,  -- SERIAL = BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE
	name VARCHAR(50) NOT NULL,
	description VARCHAR(500) NULL,
	promo_id BIGINT UNSIGNED NULL,
	age_restriction INT  NOT NULL,
	author_id BIGINT UNSIGNED NOT NULL,
	communitie_id BIGINT UNSIGNED NULL,
	version VARCHAR(15) NULL,
	created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
	
	FOREIGN KEY (author_id) REFERENCES users(id),
	FOREIGN KEY (promo_id) REFERENCES media_types(id),
	FOREIGN KEY (communitie_id) REFERENCES communities(id)
);
	
	
	