
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
  , created_at DATETIME DEFAULT NOW() COMMENT 'когда создан'
  , updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT 'когда изменён'
  , INDEX idx_users_username(surname, name)
  , INDEX idx_users_status(status)
) COMMENT 'Пользователи ВПН';


	-- 2. организации
DROP TABLE IF EXISTS `organizations`;

CREATE TABLE `organizations` (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT ''
  , name VARCHAR (100)
  , full_name VARCHAR (300)
  , main_user INT UNSIGNED NOT NULL COMMENT 'Контактное лицо'	-- main_contact, users_id 
  , description VARCHAR (200) COMMENT 'замечание'  
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
DROP TABLE IF EXISTS `user_profiles`;

CREATE TABLE `user_profiles` (
    user_id  INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'чей профиль'
  , changer_id INT UNSIGNED NOT NULL COMMENT 'кто изменял user/профиль'
  , categorys_id INT UNSIGNED NOT NULL COMMENT 'категория user (роль?)'
  , organizations_id INT UNSIGNED NOT NULL COMMENT 'от какой организации user' 
  , description VARCHAR (200) COMMENT 'замечание'
  
  , FOREIGN KEY (user_id) REFERENCES users(id)
  --  ON UPDATE CASCADE		-- (значение по умолчанию)
    ON DELETE CASCADE		-- RESTRICT -- (значение по умолчанию) сменить на удаление!!!
    
  , FOREIGN KEY (changer_id) REFERENCES users(id)
  , FOREIGN KEY (categorys_id) REFERENCES user_categorys(id)
  
) COMMENT 'профиль пользователя';    


	-- 5. контакты организаций


DROP TABLE IF EXISTS ` org_contacts`;

CREATE TABLE ` org_contacts` (
    organization_id INT UNSIGNED NOT NULL
  , user_id INT UNSIGNED NOT NULL
  , description VARCHAR (200) COMMENT  'замечание'  

  , FOREIGN KEY (organization_id) REFERENCES organizations(id)
  , FOREIGN KEY (user_id) REFERENCES users(id)

) COMMENT 'дополнительные контактные лица';



	-- 6. email's
/*
emails
        id
        user_id
        address
        description
        created_at
        updated_at
*/


	-- 7. phones
/* 
 phones
        id
        user_id
        number
        description
        created_at
        updated_at
*/





	-- 8. PKI, центры сертификации
DROP TABLE IF EXISTS ` PKIs`;

CREATE TABLE ` PKIs` (
    ca_id INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'PKI'
  , organization_id INT UNSIGNED NOT NULL 
  , ca_name VARCHAR (200) COMMENT  'имя CA'
  , ca_file_path VARCHAR (2048) COMMENT  'путь на файловой системе, где размещаются все файлы этого CA'
  , ca_key VARCHAR (2048) COMMENT  'полный путь и имя файла приватного ключа CA'
  , ca_crt VARCHAR (2048) COMMENT  'полный путь и имя файла сертификата  ключа CA'
  , ca_dh VARCHAR (2048) COMMENT  'полный путь и имя файла Diffie-Hellman key CA'
  , ca_crl VARCHAR (2048) COMMENT  'полный путь и имя файла списка отозванных сертификатов CA'
  , ta_key VARCHAR (2048) COMMENT  'полный путь к ta.key - ключ tls-auth'
  , description VARCHAR (200) COMMENT  'замечания'
  
  , FOREIGN KEY (organization_id) REFERENCES organizations(id)

  ) COMMENT 'PKI Организаций';
 

	-- 9. ключи
DROP TABLE IF EXISTS ` keys`;

CREATE TABLE ` keys` (
    id INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'key_id'
) COMMENT ''; 
/* 
  
        id
        
        ca_id
        key_dest          -- user | server
        priv
        crt
        req
        created_at
        not_before
        not_after
        status            -- active | revoked

*/

	-- 11. привязка ключей
/*
       
 key_binding
        keys_id           -- uniq
        users_id      

*/

    
	-- 12. Серверы OpenVPN
/*
 servers
        id
        keys_id
        int_ip
        int_port
        ext_ip
        ext_port
        srv_groups_id
        description        
*/

	-- 13. Servers group
/*
srv_groups
        id
        srv_params_file
        description

*/
	-- 14. группа параметров клиентов (пользовательских программ)
/*
 clnt_params_gr
        id
        name
        description
        params_file
 
*/

/*
ALTER TABLE vpn_control_db.user_profiles
ADD CONSTRAINT clnt_params_fk
FOREIGN KEY (clnt_params_gr_id) REFERENCES vpn_control_db.clnt_params_gr(id);		-- пока не существует 
*/
    
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
