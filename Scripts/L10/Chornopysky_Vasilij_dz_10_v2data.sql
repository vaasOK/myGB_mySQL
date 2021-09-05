/*
 *
 *
 * БД для администрирования системы удалённого доступа на основе OpenVPN
 *
 * 
 **/


	-- 1. пользователи 


CREATE TABLE `users` (
    u_id         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY
  , surname      VARCHAR(40)  NOT NULL
  , name         VARCHAR(20)  NOT NULL
  , middle_name  VARCHAR(30)
  , base_doc_url VARCHAR(100) NOT NULL COMMENT 'URL заявки в ServiceDesk системе'   -- основание для создания пользователя
  , status       ENUM ('active', 'paused', 'blocked', 'deleted') DEFAULT 'paused'   -- active | paused | blocked | deleted
  
  , created_at  DATETIME DEFAULT NOW() COMMENT 'датавремя создания'
  , updated_at  DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT 'датавремя изменёния'
  
  , INDEX idx_users_username(surname, name)
  , INDEX idx_users_status(status)
  
) COMMENT 'Пользователи ВПН';


	-- 2. организации


CREATE TABLE `organizations` (
    org_id      INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT ''
  , name        VARCHAR(100) NOT NULL
  , full_name   VARCHAR(300)
  , main_user   INT UNSIGNED NOT NULL COMMENT 'Контактное лицо'	-- main_contact, users_id 
  , description VARCHAR(200) COMMENT 'комментарий'
  
  , INDEX idx_org_names(name)
  , FOREIGN KEY (main_user) REFERENCES users(u_id)
    ON DELETE RESTRICT -- (значение по умолчанию)

) COMMENT '';


	-- 3. категории пользователей

DROP TABLE IF EXISTS `user_categorys`;

CREATE TABLE `user_categorys` (
    id   INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY
  , name ENUM ('normal', 'VIP', 'security', 'sys_admin')     -- normal | VIP | security | org_admin | sys_admin
) COMMENT 'категория пользователя системы';                  -- для распределния прав в системе


	-- 4. профили пользователей


CREATE TABLE `users_profiles` (
    user_id           INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'чей профиль'
  , changer_id        INT UNSIGNED NOT NULL COMMENT 'кто изменял user/профиль'
  , categorys_id      INT UNSIGNED NOT NULL COMMENT 'категория user (роль?)'
  , organizations_id  INT UNSIGNED NOT NULL COMMENT 'от какой организации user'
  , clnt_params_gr_id INT UNSIGNED
  , description       VARCHAR(200) COMMENT 'замечание'
  
  , FOREIGN KEY (user_id) REFERENCES users(u_id)
  --  ON UPDATE CASCADE		-- (значение по умолчанию)
    ON DELETE CASCADE		-- RESTRICT -- (значение по умолчанию) сменить на удаление!!!

    
  , FOREIGN KEY (changer_id) REFERENCES users(u_id)
  , FOREIGN KEY (categorys_id) REFERENCES user_categorys(id)
  
) COMMENT 'профиль пользователя';    


	-- 5. контакты организаций


CREATE TABLE `org_contacts` (

    organization_id INT UNSIGNED NOT NULL
  , user_id         INT UNSIGNED NOT NULL
  , description     VARCHAR(200) COMMENT  'замечание'  

  , FOREIGN KEY (organization_id) REFERENCES organizations(org_id)
  , FOREIGN KEY (user_id) REFERENCES users(u_id)

) COMMENT 'дополнительные контактные лица';


	-- 6. email's


CREATE TABLE `emails` (
    em_id         INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'emails id'
  , user_id       INT UNSIGNED NOT NULL COMMENT ''
  , email_address VARCHAR(120) NOT NULL UNIQUE COMMENT ''
  , description   VARCHAR(200) COMMENT ''

  , created_at    DATETIME DEFAULT NOW() COMMENT 'датавремя создания'
  , updated_at    DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT 'датавремя изменения'
  
  , FOREIGN KEY (user_id) REFERENCES users_profiles(user_id)
--  ON UPDATE CASCADE		-- (значение по умолчанию)
    ON DELETE CASCADE		-- RESTRICT -- (значение по умолчанию) сменить на удаление!!!

) COMMENT '';


	-- 7. phones


CREATE TABLE `phones` (
    ph_id       INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'phones id'
  , user_id     INT UNSIGNED NOT NULL COMMENT ''
  , phone       BIGINT unsigned NOT NULL UNIQUE COMMENT ''
  , description VARCHAR(200) COMMENT ''

  , created_at  DATETIME DEFAULT NOW() COMMENT 'датавремя создания'
  , updated_at  DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT 'датавремя изменения'

  , FOREIGN KEY (user_id) REFERENCES users_profiles(user_id)
--  ON UPDATE CASCADE		-- (значение по умолчанию)
    ON DELETE CASCADE		-- RESTRICT -- (значение по умолчанию) сменить на удаление!!!

) COMMENT '';


	-- 8. PKI, центры сертификации


CREATE TABLE `PKIs` (
    ca_id           INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'PKI'
  , organization_id INT UNSIGNED NOT NULL 
  , ca_name         VARCHAR(200)        COMMENT 'имя CA'
  , ca_file_path    VARCHAR(4096)  COMMENT 'путь на файловой системе, где размещаются все файлы этого CA'
  , ca_dh_data      VARCHAR(256)     COMMENT 'имя файл Diffie-Hellman key для CA'
  , ta_key_data     VARCHAR(256)    COMMENT 'имя файла ta.key - ключ tls-auth'
  , ca_crl_data     VARCHAR(256)    COMMENT 'имя файла CRL список отозванных сертификатов CA'
  -- , ca_crl_data TEXT (65535) COMMENT 'CRL список отозванных сертификатов CA' 
  -- такой размер столбца приводит к превышению макс. размера строки, поэтому меняем на файл
  
  , ca_key_data     VARCHAR(4096)   COMMENT 'приватный ключ CA'
  , ca_crt_data     VARCHAR(6144)   COMMENT 'сертификат  ключа CA'
  , description     VARCHAR(200)    COMMENT 'комментарий'
  
  , created_at      DATETIME DEFAULT NOW() COMMENT 'датавремя создания CA'
  , updated_at      DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT 'датавремя изменения CA'
  , changer_id      INT UNSIGNED NOT NULL COMMENT 'кто изменял user/профиль'    
  
  , FOREIGN KEY (changer_id) REFERENCES users(u_id)
  , FOREIGN KEY (organization_id) REFERENCES organizations(org_id)

) COMMENT 'PKI Организаций';
 

	-- 9. ключи


CREATE TABLE `u_keys` (
    key_id     INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'key_id'
  , ca_id      INT UNSIGNED NOT NULL
  , key_dest   BIT         -- 0 user | 1 server
  , key_data   VARCHAR (4096)
  , crt_data   VARCHAR (6144)
  , req_data   VARCHAR (2048)
  , pem_data   VARCHAR (2048)

  , not_before DATETIME COMMENT 'не использовать до даты'
  , not_after  DATETIME COMMENT 'не использовать после даты'
  
  , created_at DATETIME DEFAULT NOW() COMMENT 'датавремя создания ключа'
  , updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT 'датавремя отзыва ключа'

  , status     BIT DEFAULT 1            -- active | revoked
  , changer_id INT UNSIGNED NOT NULL COMMENT 'кто изменял user/профиль'
  
  , FOREIGN KEY (changer_id) REFERENCES users(u_id)
  , FOREIGN KEY (ca_id) REFERENCES  PKIs(ca_id)
  
) COMMENT 'ключи пользователей'; 


	-- 10. привязка ключей к пользователям


CREATE TABLE `key_binding` (
    key_id   INT UNSIGNED NOT NULL UNIQUE            -- uniq
  , user_id  INT UNSIGNED NOT NULL
  
  , FOREIGN KEY (key_id) REFERENCES  u_keys(key_id)
  , FOREIGN KEY (user_id) REFERENCES  users(u_id)
) COMMENT '';


	-- 11. Servers group


CREATE TABLE `srv_groups` (
    srv_gr_id         INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'id сервера'
  , name              VARCHAR(40)  NOT NULL UNIQUE
  -- , params_files_path VARCHAR(4096) COMMENT 'путь на файловой системе, где размещаются файлы параметров'
  -- , params_file VARCHAR(256)  COMMENT 'имя файла параметров'
  , clnt_params_gr_id INT UNSIGNED
  , description       VARCHAR(200) COMMENT 'комментарий'
) COMMENT '';


	-- 12. Серверы OpenVPN


CREATE TABLE `servers` (
    srv_id       INT UNSIGNED      NOT NULL UNIQUE PRIMARY KEY COMMENT 'id сервера'
  , key_id       INT UNSIGNED      NOT NULL COMMENT 'ключ сервера'
  
  , int_ip       INT UNSIGNED      NOT NULL COMMENT 'внутренний ip-адрес сервера'	  -- см. комментарий ниже
  , int_port     SMALLINT UNSIGNED NOT NULL COMMENT 'внутренний ip-порт сервера'
  , ext_ip       INT UNSIGNED      NOT NULL COMMENT 'внешний ip-адрес сервера'		  -- см. комментарий ниже
  , ext_port     SMALLINT UNSIGNED NOT NULL COMMENT 'внешний ip-порт сервера'
  
  , srv_group_id INT UNSIGNED      NOT NULL COMMENT 'комментарий'
     
  , created_at DATETIME DEFAULT NOW() COMMENT 'датавремя создания ключа'
  , updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT 'датавремя отзыва ключа'
  , changer_id INT UNSIGNED NOT NULL COMMENT 'кто изменял user/профиль'
  
  , description  VARCHAR (200) COMMENT 'комментарий'
  
  , FOREIGN KEY (changer_id) REFERENCES users(u_id)
  
  , FOREIGN KEY (key_id) REFERENCES u_keys(key_id)
  , FOREIGN KEY (srv_group_id) REFERENCES srv_groups(srv_gr_id)

) COMMENT '';

-- с IP-адресами работать через INET_ATON() и INET_NTOA()
-- https://dev.mysql.com/doc/refman/5.6/en/miscellaneous-functions.html
-- https://jeka.by/ask/124/mysql-ip-address/



-- 13. группа параметров клиентов (пользовательских программ)


CREATE TABLE `clnt_params_gr` (
    cl_par_id         INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT ''
  , name              VARCHAR(40)  NOT NULL UNIQUE
  , params_files_path VARCHAR(4096) COMMENT 'путь на файловой системе, где размещаются файлы параметров'
  , params_file       VARCHAR(256)  COMMENT 'имя файла параметров'
  , description       VARCHAR(200)  COMMENT 'комментарий'
) COMMENT '';


