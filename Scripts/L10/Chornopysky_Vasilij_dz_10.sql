/*
 *
 *
 * БД для администрирования системы удалённого доступа на основе OpenVPN
 *
 * 
 **/

DROP DATABASE IF EXISTS vpn_control_db;
CREATE DATABASE vpn_control_db;
USE vpn_control_db;


	-- 1. пользователи 
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (

    id  INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY
  , surname VARCHAR(40) NOT NULL
  , name VARCHAR(20) NOT NULL
  , middle_name VARCHAR(30)
  , base_doc_url VARCHAR(100) NOT NULL COMMENT 'URL заявки в ServiceDesk системе'   -- основание для создания пользователя
  , status  ENUM ('active', 'paused', 'blocked', 'deleted') DEFAULT 'paused'   -- active | paused | blocked | deleted
  
  , created_at DATETIME DEFAULT NOW() COMMENT 'датавремя создания'
  , updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT 'датавремя изменёния'
  
  , INDEX idx_users_username(surname, name)
  , INDEX idx_users_status(status)
  
) COMMENT 'Пользователи ВПН';


	-- 2. организации
DROP TABLE IF EXISTS `organizations`;
CREATE TABLE `organizations` (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT ''
  , name VARCHAR(100) NOT NULL
  , full_name VARCHAR(300)
  , main_user INT UNSIGNED NOT NULL COMMENT 'Контактное лицо'	-- main_contact, users_id 
  , description VARCHAR(200) COMMENT 'комментарий'
  
  , INDEX idx_org_names(name)
  , FOREIGN KEY (main_user) REFERENCES users(id)
    ON DELETE RESTRICT -- (значение по умолчанию)

) COMMENT '';


	-- 3. категории пользователей
DROP TABLE IF EXISTS `user_categorys`;
CREATE TABLE `user_categorys` (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY
  , name ENUM ('normal', 'VIP', 'security', 'sys_admin')     -- normal | VIP | security | org_admin | sys_admin
) COMMENT 'категория пользователя системы';                  -- для распределния прав в системе


	-- 4. профили пользователей
DROP TABLE IF EXISTS `users_profiles`;
CREATE TABLE `users_profiles` (

    user_id  INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'чей профиль'
  , changer_id INT UNSIGNED NOT NULL COMMENT 'кто изменял user/профиль'
  , categorys_id INT UNSIGNED NOT NULL COMMENT 'категория user (роль?)'
  , organizations_id INT UNSIGNED NOT NULL COMMENT 'от какой организации user'
  , clnt_params_gr_id INT UNSIGNED
  , description VARCHAR(200) COMMENT 'замечание'
  
  , FOREIGN KEY (user_id) REFERENCES users(id)
  --  ON UPDATE CASCADE		-- (значение по умолчанию)
    ON DELETE CASCADE		-- RESTRICT -- (значение по умолчанию) сменить на удаление!!!
    
  , FOREIGN KEY (changer_id) REFERENCES users(id)
  , FOREIGN KEY (categorys_id) REFERENCES user_categorys(id)
  
) COMMENT 'профиль пользователя';    


	-- 5. контакты организаций
DROP TABLE IF EXISTS `org_contacts`;
CREATE TABLE `org_contacts` (

    organization_id INT UNSIGNED NOT NULL
  , user_id INT UNSIGNED NOT NULL
  , description VARCHAR(200) COMMENT  'замечание'  

  , FOREIGN KEY (organization_id) REFERENCES organizations(id)
  , FOREIGN KEY (user_id) REFERENCES users(id)

) COMMENT 'дополнительные контактные лица';


	-- 6. email's
DROP TABLE IF EXISTS `emails`;
CREATE TABLE `emails` (
    id INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'emails id'
  , user_id INT UNSIGNED NOT NULL COMMENT ''
  , email_address varchar(120) NOT NULL UNIQUE COMMENT ''
  , description varchar(200) COMMENT ''

  , created_at DATETIME DEFAULT NOW() COMMENT 'датавремя создания'
  , updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT 'датавремя изменения'
  
  , FOREIGN KEY (user_id) REFERENCES users_profiles(user_id)
--  ON UPDATE CASCADE		-- (значение по умолчанию)
    ON DELETE CASCADE		-- RESTRICT -- (значение по умолчанию) сменить на удаление!!!

) COMMENT '';


	-- 7. phones
DROP TABLE IF EXISTS `phones`;
CREATE TABLE `phones` (
    id INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'phones id'
  , user_id INT UNSIGNED NOT NULL COMMENT ''
  , phone bigint unsigned NOT NULL UNIQUE COMMENT ''
  , description varchar(200) COMMENT ''

  , created_at DATETIME DEFAULT NOW() COMMENT 'датавремя создания'
  , updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT 'датавремя изменения'

  , FOREIGN KEY (user_id) REFERENCES users_profiles(user_id)
--  ON UPDATE CASCADE		-- (значение по умолчанию)
    ON DELETE CASCADE		-- RESTRICT -- (значение по умолчанию) сменить на удаление!!!

) COMMENT '';


	-- 8. PKI, центры сертификации
DROP TABLE IF EXISTS `PKIs`;
CREATE TABLE `PKIs` (
    ca_id INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'PKI'
  , organization_id INT UNSIGNED NOT NULL 
  , ca_name VARCHAR(200)        COMMENT 'имя CA'
  , ca_file_path VARCHAR(4096)  COMMENT 'путь на файловой системе, где размещаются все файлы этого CA'
  , ca_dh_data VARCHAR(256)     COMMENT 'имя файл Diffie-Hellman key для CA'
  , ta_key_data VARCHAR(256)    COMMENT 'имя файла ta.key - ключ tls-auth'
  , ca_crl_data VARCHAR(256)    COMMENT 'имя файла CRL список отозванных сертификатов CA'
  -- , ca_crl_data TEXT (65535) COMMENT 'CRL список отозванных сертификатов CA' 
  -- такой размер столбца приводит к превышению макс. размера строки, поэтому меняем на файл
  
  , ca_key_data VARCHAR(4096)   COMMENT 'приватный ключ CA'
  , ca_crt_data VARCHAR(6144)   COMMENT 'сертификат  ключа CA'
  , description VARCHAR(200)    COMMENT 'комментарий'
  
  , created_at DATETIME DEFAULT NOW() COMMENT 'датавремя создания CA'
  , updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT 'датавремя изменения CA'

  , FOREIGN KEY (organization_id) REFERENCES organizations(id)

) COMMENT 'PKI Организаций';
 

	-- 9. ключи
DROP TABLE IF EXISTS `u_keys`;
CREATE TABLE `u_keys` (
    id INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'key_id'
  , ca_id INT UNSIGNED NOT NULL
  , key_dest BIT         -- 0 user | 1 server
  , key_data VARCHAR (4096)
  , crt_data VARCHAR (6144)
  , req_data VARCHAR (2048)
  , pem_data VARCHAR (2048)

  , not_before DATETIME COMMENT 'не использовать до даты'
  , not_after  DATETIME COMMENT 'не использовать после даты'
  
  , created_at DATETIME DEFAULT NOW() COMMENT 'датавремя создания ключа'
  , updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT 'датавремя отзыва ключа'

  , status BIT DEFAULT 1            -- active | revoked
  
  , FOREIGN KEY (ca_id) REFERENCES  PKIs(ca_id)
  
) COMMENT 'ключи пользователей'; 


	-- 10. привязка ключей к пользователям
DROP TABLE IF EXISTS `key_binding`;
CREATE TABLE `key_binding` (
    key_id INT UNSIGNED NOT NULL UNIQUE            -- uniq
  , user_id INT UNSIGNED NOT NULL
  
  , FOREIGN KEY (key_id) REFERENCES  u_keys(id)
  , FOREIGN KEY (user_id) REFERENCES  users(id)
) COMMENT '';


	-- 11. Servers group
DROP TABLE IF EXISTS `srv_groups`;
CREATE TABLE `srv_groups` (
    id INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'id сервера'
  , name VARCHAR(40) NOT NULL UNIQUE
  -- , params_files_path VARCHAR(4096) COMMENT 'путь на файловой системе, где размещаются файлы параметров'
  -- , params_file VARCHAR(256)  COMMENT 'имя файла параметров'
  , clnt_params_gr_id INT UNSIGNED
  , description VARCHAR(200) COMMENT 'комментарий'
) COMMENT '';


	-- 12. Серверы OpenVPN
DROP TABLE IF EXISTS `servers`;

CREATE TABLE `servers` (
    id INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'id сервера'
  , key_id INT UNSIGNED NOT NULL COMMENT 'ключ сервера'
  
  , int_ip INT UNSIGNED NOT NULL COMMENT 'внутренний ip-адрес сервера'	  -- см. комментарий ниже
  , int_port SMALLINT UNSIGNED NOT NULL COMMENT 'внутренний ip-порт сервера'
  , ext_ip INT UNSIGNED NOT NULL COMMENT 'внешний ip-адрес сервера'		  -- см. комментарий ниже
  , ext_port SMALLINT UNSIGNED NOT NULL COMMENT 'внешний ip-порт сервера'
  
  , srv_group_id INT UNSIGNED NOT NULL COMMENT 'комментарий'
  
  , description VARCHAR (200) COMMENT 'комментарий'
  
  , FOREIGN KEY (key_id) REFERENCES u_keys(id)
  , FOREIGN KEY (srv_group_id) REFERENCES srv_groups(id)

) COMMENT '';

-- с IP-адресами работать через INET_ATON() и INET_NTOA()
-- https://dev.mysql.com/doc/refman/5.6/en/miscellaneous-functions.html
-- https://jeka.by/ask/124/mysql-ip-address/

-- 13. группа параметров клиентов (пользовательских программ)
DROP TABLE IF EXISTS `clnt_params_gr`;

CREATE TABLE `clnt_params_gr` (
    id INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT ''
  , name VARCHAR(40) NOT NULL UNIQUE
  , params_files_path VARCHAR(4096) COMMENT 'путь на файловой системе, где размещаются файлы параметров'
  , params_file VARCHAR(256)  COMMENT 'имя файла параметров'
  , description VARCHAR(200) COMMENT 'комментарий'
) COMMENT '';


ALTER TABLE vpn_control_db.users_profiles
ADD CONSTRAINT clnt_params_fk
FOREIGN KEY (clnt_params_gr_id) REFERENCES vpn_control_db.clnt_params_gr(id)
; 

ALTER TABLE vpn_control_db.srv_groups
ADD CONSTRAINT srv_gr_params_fk
FOREIGN KEY (clnt_params_gr_id) REFERENCES vpn_control_db.clnt_params_gr(id)
; 


/*

Старое "ТЗ" программисту

Пожелания к усовершенствованию админки OpenVPN (ovpn.firma.ru)

    Добавить в админку возможность редактирования примечания
    Добавить в админку нередактируемое поле  «основание выпуска ключей»
    Добавить в админку автогенератор паролей ключей, с  возможностью изменения параметров пароля (длина, символы, сложность)
    Добавить в админку поле e-mail
    При выпуске ключей
        кидать на этот e-mail пароль ключа
        Добавлять к этому письму некий «стандартный» текст, с правилами, предупреждениями и инструкцией (ссылкой на неё?)
        Включить в этот текст срок действия ключа и дату время окончания этого срока
        Включить в этот текст перечень действий, необходимых для инициирования продления (перевыпуска) ключей 
    Добавить в админку возможность изменения срока действия ключа (конечно же, только в момент выпуска ключа)
    Добавить в админку отображения даты выдачи ключа, срока действия ключа, даты и времени окончания срока действия ключа
    При окончании срока действия ключа – кидать на привязанный e-mail оповещения/предупреждения, за какой-то срок (месяц/пара недель/последняя неделя ежедневно)
    Добавить в админку возможность экспорта списка ключей / пользователей (типа отчёт)
    Администрирование админки – пользователи, права, и т.д. – обговариваемо… (чтобы запустить сюда СБ – пусть сами смотрят кто и что и сами себе отчёты генерят)

*/
