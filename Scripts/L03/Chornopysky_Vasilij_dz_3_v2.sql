/*
 *
 * 1. Написать крипт, 
 * 		добавляющий в БД vk, которую создали на занятии, 
 * 			3 новые таблицы (с перечнем полей, указанием индексов и внешних ключей) 
 */


DROP TABLE IF EXISTS age_restrictions;
CREATE TABLE age_restrictions(
	
    id  SERIAL,  -- SERIAL = BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE
	
    name VARCHAR(10) NOT NULL COMMENT 'имя категории ограничений возраста',
    min_age TINYINT COMMENT 'минимальный возраст для категории',
	
    PRIMARY KEY (name)
);


DROP TABLE IF EXISTS games;
CREATE TABLE games(
	
    id SERIAL,  -- SERIAL = BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE
	
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(500) NULL COMMENT 'Описание игры',
	
    promo_id BIGINT UNSIGNED NULL COMMENT 'проморолик',
    age_restriction_id BIGINT UNSIGNED NOT NULL COMMENT 'возрастные ограничения',
    author_id BIGINT UNSIGNED NOT NULL COMMENT 'автор игры',
    communitie_id BIGINT UNSIGNED NULL COMMENT 'сообщество игры',
	
    version_of_code VARCHAR(15) NULL COMMENT 'версия кода игры',
    created_at DATETIME DEFAULT NOW() COMMENT 'создана в VK',
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT 'обновлена в VK',
	
    FOREIGN KEY (author_id) REFERENCES users(id),
    FOREIGN KEY (promo_id) REFERENCES media_types(id),
    FOREIGN KEY (communitie_id) REFERENCES communities(id),
    FOREIGN KEY (age_restriction_id) REFERENCES age_restrictions(id)
);
	
	
DROP TABLE IF EXISTS game_scores;
CREATE TABLE game_scores(
	
    game_id  BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
	
    score BIGINT DEFAULT 0 COMMENT 'количество игровых очков пользователя',
    created_at DATETIME DEFAULT NOW() COMMENT 'дата первого сохранённого результата ',
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT 'обновление счёта очков',
    
    PRIMARY KEY (game_id, user_id),	-- хранятся только макс. результаты (max будет обрабатыватьс алгоритмом движка игры) 
    FOREIGN KEY (game_id) REFERENCES games(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);
