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


	-- 1. пользователи ( data + )

DROP TABLE IF EXISTS `users`;

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


	-- 2. организации ( data + )

DROP TABLE IF EXISTS `organizations`;

CREATE TABLE `organizations` (
    org_id      INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT ''
  , name        VARCHAR(100) NOT NULL
  , full_name   VARCHAR(300)
  , main_user   INT UNSIGNED NOT NULL COMMENT 'Контактное лицо'	-- main_contact, users_id 
  , description VARCHAR(200) COMMENT 'комментарий'
  
  , INDEX idx_org_names(name)
  , FOREIGN KEY (main_user) REFERENCES users(u_id)
    ON DELETE RESTRICT -- (значение по умолчанию)

) COMMENT 'Организации';


	-- 3. категории пользователей ( data + )

DROP TABLE IF EXISTS `user_categorys`;

CREATE TABLE `user_categorys` (
    u_cat_id   INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY
  , name ENUM ('normal', 'VIP', 'security', 'sys_admin')     -- normal | VIP | security | org_admin | sys_admin
) COMMENT 'Категория пользователя системы';                  -- для распределния прав в системе


	-- 4. профили пользователей ( data + )

DROP TABLE IF EXISTS `users_profiles`;

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
  , FOREIGN KEY (categorys_id) REFERENCES user_categorys(u_cat_id)
  , FOREIGN KEY (organizations_id) REFERENCES organizations(org_id)
) COMMENT 'Профиль пользователя';    


	-- 5. контакты организаций ( data + )

DROP TABLE IF EXISTS `org_contacts`;

CREATE TABLE `org_contacts` (

    organization_id INT UNSIGNED NOT NULL
  , user_id         INT UNSIGNED NOT NULL
  , description     VARCHAR(200) COMMENT  'замечание'  

  , FOREIGN KEY (organization_id) REFERENCES organizations(org_id)
  , FOREIGN KEY (user_id) REFERENCES users(u_id)
  
  , INDEX idx_org_contacts(organization_id, user_id)


) COMMENT 'Дополнительные контактные лица';


	-- 6. email's ( data + )

DROP TABLE IF EXISTS `emails`;

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

) COMMENT 'e-mails контакты';


	-- 7. phones ( data + )

DROP TABLE IF EXISTS `phones`;

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

) COMMENT 'Телефоны контакты';


	-- 8. PKI, центры сертификации. ( data + )

DROP TABLE IF EXISTS `PKIs`;

CREATE TABLE `PKIs` (
    ca_id           INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'PKI'
  , organization_id INT UNSIGNED NOT NULL 
  , ca_name         VARCHAR(200)    COMMENT 'имя CA'
  , ca_file_path    VARCHAR(4096)   COMMENT 'путь на файловой системе, где размещаются все файлы этого CA'
  , ca_dh_data      VARCHAR(256)    COMMENT 'имя файл Diffie-Hellman key для CA'
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
 

	-- 9. ключи ( data + )

DROP TABLE IF EXISTS `vpn_keys`;

CREATE TABLE `vpn_keys` (
    key_id     INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'key_id'
  , ca_id      INT UNSIGNED NOT NULL
  , key_dest   BIT         -- 0 user | 1 server
    -- Длина поля рассчитана на размещене в нём ключа, но для создания БД пишем сюда имена файлов с ключами
  , key_data   VARCHAR (4096) COMMENT 'user_xx.key'
    -- Длина поля рассчитана на размещене в нём ключа, но для создания БД пишем сюда имена файлов с ключами
  , crt_data   VARCHAR (6144) COMMENT 'user_xx.crt'
    -- Длина поля рассчитана на размещене в нём ключа, но для создания БД пишем сюда имена файлов с ключами
  , req_data   VARCHAR (2048) COMMENT 'user_xx.req`'
    -- Длина поля рассчитана на размещене в нём ключа, но для создания БД пишем сюда имена файлов с ключами
  , pem_data   VARCHAR (2048) COMMENT 'user_xx.pem'

  , not_before DATETIME COMMENT 'не использовать до даты'
  , not_after  DATETIME COMMENT 'не использовать после даты'
  
  , created_at DATETIME DEFAULT NOW() COMMENT 'датавремя создания ключа'
  , updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT 'датавремя отзыва ключа'

  , status     BIT DEFAULT 1            -- revoked 0 | active 1
  , changer_id INT UNSIGNED NOT NULL COMMENT 'кто изменял user/профиль'
  
  , FOREIGN KEY (changer_id) REFERENCES users(u_id)
  , FOREIGN KEY (ca_id) REFERENCES  PKIs(ca_id)
  
) COMMENT 'Ключи пользователей'; 


	-- 10. привязка ключей к пользователям ( data + )

DROP TABLE IF EXISTS `key_binding`;

CREATE TABLE `key_binding` (
    key_id   INT UNSIGNED NOT NULL UNIQUE            -- uniq
  , user_id  INT UNSIGNED NOT NULL
  
  , FOREIGN KEY (key_id) REFERENCES  vpn_keys(key_id)
  , FOREIGN KEY (user_id) REFERENCES  users(u_id)
) COMMENT 'Пользователи и их ключи';


	-- 11. Servers group ( data + )

DROP TABLE IF EXISTS `srv_groups`;

CREATE TABLE `srv_groups` (
    srv_gr_id         INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT 'id сервера'
  , name              VARCHAR(40)  NOT NULL UNIQUE
  -- , params_files_path VARCHAR(4096) COMMENT 'путь на файловой системе, где размещаются файлы параметров'
  -- , params_file VARCHAR(256)  COMMENT 'имя файла параметров'
  , clnt_params_gr_id INT UNSIGNED
  , description       VARCHAR(200) COMMENT 'комментарий'
) COMMENT 'Группы серверов';


	-- 12. Серверы OpenVPN ( data + )

DROP TABLE IF EXISTS `servers`;

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
  
  , FOREIGN KEY (key_id) REFERENCES vpn_keys(key_id)
  , FOREIGN KEY (srv_group_id) REFERENCES srv_groups(srv_gr_id)

) COMMENT 'Серверы';

-- с IP-адресами работать через INET_ATON() и INET_NTOA()
-- https://dev.mysql.com/doc/refman/5.6/en/miscellaneous-functions.html
-- https://jeka.by/ask/124/mysql-ip-address/



-- 13. группа параметров клиентов (пользовательских программ) ( data + )

DROP TABLE IF EXISTS `clnt_params_gr`;

CREATE TABLE `clnt_params_gr` (
    cl_par_id         INT UNSIGNED NOT NULL UNIQUE PRIMARY KEY COMMENT ''
  , name              VARCHAR(40)  NOT NULL UNIQUE
  , params_files_path VARCHAR(4096) COMMENT 'путь на файловой системе, где размещаются файлы параметров'
  , params_file       VARCHAR(256)  COMMENT 'имя файла параметров'
  , description       VARCHAR(200)  COMMENT 'комментарий'
) COMMENT 'Группы параметров ВПН';




ALTER TABLE vpn_control_db.users_profiles
ADD CONSTRAINT clnt_params_fk
FOREIGN KEY (clnt_params_gr_id) REFERENCES vpn_control_db.clnt_params_gr(cl_par_id)
; 

ALTER TABLE vpn_control_db.srv_groups
ADD CONSTRAINT srv_gr_params_fk
FOREIGN KEY (clnt_params_gr_id) REFERENCES vpn_control_db.clnt_params_gr(cl_par_id); 





INSERT INTO vpn_control_db.clnt_params_gr
 (cl_par_id, name, params_files_path, params_file, description) 
VALUES
 (1, 'srv_srv_1', '$oVPN_manager/params', 'param_1.conf', 'параметры серверов ВПН УК')
,(2, 'srv_srv_2', '$oVPN_manager/params', 'param_2.conf', 'параметры серверов ВПН магазинов')
,(3, 'srv_srv_3', '$oVPN_manager/params', 'param_3.conf', 'параметры серверов ВПН АСалона')
,(4, 'cl_admin', '$oVPN_manager/params', 'param_4.conf', 'параметры админа')
,(5, 'cl_SB', '$oVPN_manager/params', 'param_4.conf', 'параметры СБ')
,(6, 'cl_VIP', '$oVPN_manager/params', 'param_4.conf', 'параметры VIP')
,(7, 'cl_user', '$oVPN_manager/params', 'param_4.conf', 'параметры простых юзеров')
;


INSERT INTO vpn_control_db.users 
  (u_id, surname,     name,          middle_name,   base_doc_url,                            status,    created_at,           updated_at) 
VALUES
  (1,    'Clara',    'Bogisich',    'DuBuque',     'http://help.myfirm.ru/Task/View/57586', 'active',  '2020-10-03 15:15:00', '2021-06-24 09:31:01')
, (2,    'Martina',  'Lehner',      'Lebsack',     'http://help.myfirm.ru/Task/View/57564', 'active',  '2020-10-04 19:12:00', '2021-06-25 09:32:01')
, (3,    'Gladyce',  'Oberbrunner', 'McGlynn',     'http://help.myfirm.ru/Task/View/57553', 'blocked', '2020-10-05 19:16:58', '2021-06-26 09:33:01')
, (4,    'Lilyan',   'Waters',      'McGlynn',     'http://help.myfirm.ru/Task/View/57592', 'paused',  '2020-11-23 09:16:28', '2021-06-27 09:34:01')
, (5,    'Colleen',  'Feeney',      'DuBuque',     'http://help.myfirm.ru/Task/View/57536', 'active',  '2020-12-03 10:37:41', '2021-06-28 09:35:01')
, (6,    'Royal',    'Turner',      'Zulauf',      'http://help.myfirm.ru/Task/View/57573', 'active',  '2021-02-28 11:44:22', '2021-06-29 09:36:01')
, (7,    'Bonita',   'Parisian',    'Lehner',      'http://help.myfirm.ru/Task/View/57510', 'deleted', '2021-02-03 19:16:58', '2021-06-30 09:37:01')
, (8,    'Herbert',  'Wiza',        'Oberbrunner', 'http://help.myfirm.ru/Task/View/57537', 'paused',  '2021-03-19 19:16:58', '2021-07-01 09:38:01')
, (9,    'Zita',     'Wilkinson',   'Rodriguez',   'http://help.myfirm.ru/Task/View/57512', 'deleted', '2021-04-16 19:16:58', '2021-07-02 09:39:01')
, (10,   'Herbert',  'Wiza',        'Stoltenberg', 'http://help.myfirm.ru/Task/View/57554', 'active',  '2021-05-27 19:16:58', '2021-07-03 09:40:01')
, (11,   'Wilton',   'Zulauf',      'Homenick',    'http://help.myfirm.ru/Task/View/57598', 'active',  '2021-06-23 19:16:58', '2021-06-07 09:41:01')
;


INSERT INTO vpn_control_db.organizations
 (org_id,   name,        full_name,                main_user,   description )
VALUES
 (1,        'УК',        'УК Главная Компания',    1,           'Самая Главная Компания' )
,(2,        'Магазин-1', 'ООО Первый Магазин',     1,           'Магазин' )
,(3,        'Магазин-2', 'ООО Второй Магазин',     4,           'Ещё Магазин' )
,(4,        'Салон-3',   'ООО Автосалон',          2,           'Масынки' )
,(5,        'СТО-4',     'ООО СТО при Автосалоне', 2,           'Гаечки' )
;


INSERT INTO vpn_control_db.user_categorys 
 (u_cat_id, name)
VALUES
 (1, 'sys_admin')
,(2, 'security')
,(3, 'normal')
,(4, 'VIP')
;


INSERT INTO vpn_control_db.users_profiles
 (user_id , changer_id , categorys_id , organizations_id , clnt_params_gr_id , description) 
VALUES
 (1, 1, 1, 1, 4, 'главный админ')
,(2, 1, 1, 1, 4, 'первый амин')
,(3, 1, 1, 1, 4, 'второй админ')
,(4, 1, 2, 1, 5, 'сотрудник СБ')
,(5, 1, 3, 1, 7, 'сотрудник УК')
,(6, 1, 3, 2, 7, 'сотрудник маг 1')
,(7, 1, 3, 3, 7, 'сотрудник маг 2')
,(8, 1, 4, 1, 6, 'директор всея конторы')
,(9, 1, 3, 1, 7, 'сотрудник УК')
,(10, 1, 3, 4, 7, 'сотрудник салона')
,(11, 1, 3, 5, 7, 'сотрудник СТО')
;


INSERT INTO vpn_control_db.org_contacts
 (organization_id, user_id, description)
VALUES
 (1, 2, 'контакт в УК')
,(2, 2, 'контакт в маг 1')
,(3, 3, 'контакт в маг 2')
,(4, 3, 'контакт в салоне')
,(5, 3, 'контакт в СТО')
;



INSERT INTO vpn_control_db.emails
 (em_id, user_id, email_address, description, created_at, updated_at)
VALUES
 (1,  4, 'user1@uk-firm.ru', 'почта УК',     '2020-11-23 09:16:30', '2021-06-27 09:34:05')
,(2,  5, 'user2@uk-firm.ru', 'почта УК',     '2020-12-03 10:37:48', '2021-06-28 09:40:01')
,(3,  6, 'user3@uk-firm.ru', 'почта маг 1',  '2021-02-28 11:50:22', '2021-06-29 09:50:01')
,(4,  7, 'user4@uk-firm.ru', 'почта маг 2',  '2021-02-03 19:25:58', '2021-06-30 09:47:01')
,(5,  9, 'user5@uk-firm.ru', 'почта УК ',    '2021-04-17 15:11:05', '2021-07-08 15:30:31')
,(6, 10, 'user6@uk-firm.ru', 'почта салона', '2021-05-27 13:47:00', '2021-09-24 13:25:19')
,(7, 11, 'user7@uk-firm.ru', 'почта СТО',    '2021-06-24 11:38:05', '2021-08-12 18:15:24')
;


INSERT INTO vpn_control_db.phones
 (ph_id, user_id, phone, description, created_at, updated_at)
VALUES
 (1,  4, 78123344535, 'телефон УК',     '2020-11-23 09:16:30', '2021-06-27 09:34:05')
,(2,  5, 78123344536, 'телефон УК',     '2020-12-03 10:37:48', '2021-06-28 09:40:01')
,(3,  6, 78123344531, 'телефон маг 1',  '2021-02-28 11:50:22', '2021-06-29 09:50:01')
,(4,  7, 78123344532, 'телефон маг 2',  '2021-02-03 19:25:58', '2021-06-30 09:47:01')
,(5,  9, 78123344537, 'телефон УК ',    '2021-04-17 15:11:05', '2021-07-08 15:30:31')
,(6, 10, 78123344549, 'телефон салона', '2021-05-27 13:47:00', '2021-09-24 13:25:19')
,(7, 11, 78123344548, 'телефон СТО',    '2021-06-24 11:38:05', '2021-08-12 18:15:24')
;



INSERT INTO vpn_control_db.PKIs
  (ca_id, organization_id, ca_name,     ca_file_path,            ca_dh_data, ta_key_data,    ca_crl_data
 , ca_key_data
 , ca_crt_data
 , description, created_at, updated_at, changer_id
 )
VALUES
(1,       1,              'ca_UK', '$oVPN_manager/PKIs/ca_UK', 'ca_UK.dh',  'ta.ca_UK.key', 'ta.ca_UK.crl'
	, '-----BEGIN RSA PRIVATE KEY-----
	MIIEowIBAAKCAQEArcTFRmg64eSK5xwa1/pFjfJUzgHZE7PJNqQzhOuexgAyhR2F
	4aZqHy8axXVfIYwGzvJnjZhmipTIp347EoL3LS3unhI82BgM+WRbqh2iVLmTfvkh
	Fcj0S5IfkvEtVTlJGI/AEvlD2UTHvQCGwoEIIysaV715RVepFw/N6QJlt5NLkNvr
	9k4/yZtb8g9jY7c3LThs/7BPvVZFn4823ZmmB6sR3Kupa1oqpqL/22OC5N6IIry3
	VjQsoeaj5GkIn50O/82k1Cfv/d6Abt0wx0FMH1AIoTPHO6PNuSbAJVVrVc6QML/M
	PGKxtdnLpzoBAY0VvVisO2vMpavWd2yqWkHjrwIDAQABAoIBAHYmJDwLAn409nzN
	DzNqZ4BsFF09xGsxAs60NpNZ4UqfN7pqqG0UyXMKhBleBKC6pKZxCxerV41CPGwl
	1+RuR8HgSS4RGG2VbLzlD65LF+SjiTX8DhLR38jCQdWXRkt798dLdj1wXkGMEoLf
	qMD3GqFO3Upq+dm8EKwtgsO7bY2y6eDTNUv9b8z/OJRme4+Ex8E+sMJ4SWFUEw/c
	MGbv6Z8mNu6z2s+kIRnR+PpzgZpNerAY/B2nPJlEgYtG2Llvja3xTBveKcOG93dZ
	NSOdqfQsgn0oymqYEp6s9/pyGMWnWfZ+X2USaM4tHJfHcyiHy5MZ1tB1y8/cnYFY
	N9T9N4ECgYEA2mztCsc25tHXtOBdFj1205T284U0TsxlID13/h3ob8VPVIKAInMY
	gaDp+MBvXfmCU9lR6ozlEng/j4xoGLA/DWePLhyFyd8tUnOQ52c8UHRmSTT7Bk4x
	R8nPM+QSQojTxtJlqs6QTBi8dUrvga+ITJ3W14mV5q/xxtODOs4I8bkCgYEAy6k8
	Pe/VPt/HTCNxUD2BbWVLY/ZXiO3UzyN/Ls2plEy/EkJMyz8Wc/7nJ/EO0vA8vRRE
	B/ICv7WkWgVpD43iJdNybuuaBwp3HUL+FP+UBrAGBWk3Jb7UQE/chPNY7Rl1CzJG
	rl94yUCzMtnU9Z9x9tZOkul3m9bK/VwWsze31KcCgYAfj+nYytyWEfB3hIwu8IbB
	IB9nJPJgCIz8UaWLJMs3i21hKtJVKAh8gsIMXdI55Bn+/8IkgGOBfbrBhWptVtpl
	l3dLFHgIqaUk6uofZf2DKq61GWDEknvwgardNrGkx5zCeBiUy/Bx7okc8c0WEkVB
	vPUUhB8TDI2FS38E+ky0kQKBgQCs5Jqzqer547d5N412pQA/MoLx9asSH3VN88CA
	py+TKiP7CDXRRVl2V6s9CTOgdznY+l9Wr2kN/tHrajRqc/TMT9kRuQkleQjt2nWA
	tgegNcamyU97x6jAgAuhAkU34yitvJw470vG7hoyzSIw8o75Ea3aokBcF9hzhb3v
	nxl8eQKBgHZzjpg0WTakJ1YZZ1FLtNpACkdKCCo+SeuVLFGy2+yrvWi99bpF3Vv3
	xzmaxhoLUCpT7ZYO/8qE84NiZlVjVS6KM6K2D7r8CmyTWiQyfiZpa6v3g46mB6BR
	FjlM7CxwXoDYsiI2mviFW+Qr6rsPSkJEI5tr7EPUzQNtF3pp03nl
	-----END RSA PRIVATE KEY-----'
	, '-----BEGIN CERTIFICATE-----
	MIIDSzCCAjOgAwIBAgIUc1LtNmoxmoT7SbFnzfbNYg/eQnYwDQYJKoZIhvcNAQEL
	BQAwFjEU4BIyA1TEAwwLRWFzeS1SU0EgQ0EwHhcNMjAwMTIzMDkyMjU1WhcNMzAw
	MTIwMDkyMjU1WjAWMRQwEgYDVQQDDAtFYXN5LVJTQSBDQTCCASIwDQYJKoZIhvcN
	AQEBBQADggEPADCCAQoCggEBAK3ExUZoOuHkiuccGtf6RY3yVM4B2ROzyTakM4Tr
	nsYsModdheGmah8vGsV1XyGMBs7yZ42YZoqUyKd+OxKC9y0t7p4SPNgYDPlkW6od
	olS5k375IRXI9EuSH5LxLVU5SRiPwBL5Q9lEx70AhsKBCCMrGle9eUVXqRcPzekC
	ZbeTS5Db6/ZOP8mwW/IPY2O3Ny04bP+wT71WRZ+PNt2ZpgerEdyrqWtaKqai/9tj
	guTeiCK8t1Y0LKHmo+RpCJ+dDv/NpNQn7/3egG7dMMdBTB9QCKEzxzujzbkmwCVV
	a1XOkDC/zDxisbXZy6cf6AQNFb1YrDtrzKWr1ndsqlpB468CAwEAAaOBkDCBjTAd
	BgNVHQ4EFgQUGm+J4vaFQhg0L/saAyE/Ba6strgwUQYDVR0jBEowSIAUGm+J4vaF
	QhK0L/saAyE/Ba6strihGqQYMBYxFDASBgNVBAMMC0Vhc3ktUlNBIENBghRzUu02
	ajGahPtJsWfN9s1iD95CdjAMBgNVHRMEBTADAQH/MAsGA1UdDwQEAwIBBjANBgkq
	hkiG9w0BAQsFAAOCAQEAag2VE+GXaCPck1dPlSFbKMWTjivXkZcUtQX/eHc1w+k/
	+Gn0XPwgWRnPaSmGcFCm82t2ShQB3nK1634b9kvccveVoDKm8W9fTuI2f2K/bP80
	BYsHNJkEQT1NEaor/UidMIWvSV3BykmiqXnXjy+ifeZ9ghapAkkfCow2F4sfFkB
	3JxPDkHvCtxvaAnoaiuxqvbZF3yAVJgBldoIj6ILD6JZl75A6K9BK71RlLRKs5bC
	DaFD5bjRMjCjMsOHeroZE35PYaIrBQX5rS9ch75GFuJysQ9x/s6iYPDsiIcwTajm
	7O4CumkQtTs1z1THTULN/b0A1lRwJID6oM1zsWlVJw==
	-----END CERTIFICATE-----'
	, 'CA UK', '2021-01-03 11:15:25', '2021-01-03 11:15:25', 3)
,(2, 2, 'ca_M1', '$oVPN_manager/PKIs/ca_M1', 'ca_M1.dh', 'ta.ca_M1.key', 'ta.ca_M1.crl'
	, '-----BEGIN RSA PRIVATE KEY-----
	MIIEowIBAAKCAQEArcTFRmg64eSK5xwa1/pFjfJUzgHZE7PJNqQzhOuexgAyhR2F
	4aZqHy8axXVfIYwGzvJnjZhmipTIp347EoL3LS3unhI82BgM+WRbqh2iVLmTfvkh
	Fcj0S5IfkvEtVTlJGI/AEvlD2UTHvQCGwoEIIysaV715RVepFw/N6QJlt5NLkNvr
	9k4/yZtb8g9jY7c3LThs/7BPvVZFn4823ZmmB6sR3Kupa1oqpqL/22OC5N6IIry3
	VjQsoeaj5GkIn50O/82k1Cfv/d6Abt0wx0FMH1AIoTPHO6PNuSbAJVVrVc6QML/M
	PGKxtdnLpzoBAY0VvVisO2vMpavWd2yqWkHjrwIDAQABAoIBAHYmJDwLAn409nzN
	DzNqZ4BsFF09xGsxAs60NpNZ4UqfN7pqqG0UyXMKhBleBKC6pKZxCxerV41CPGwl
	1+Ru348HgS4RGG2VbLzlD65LF+SjiTX8DhLR38jCQdWXRkt798dLdj1wXkGMEoLf
	qMD3GqFO3Upq+dm8EKwtgsO7bY2y6eDTNUv9b8z/OJRme4+Ex8E+sMJ4SWFUEw/c
	MGbv6Z8mNu6z2s+kIRnR+PpzgZpNerAY/B2nPJlEgYtG2Llvja3xTBveKcOG93dZ
	NSOdqfQsg5oymqYEp6s9/pyGMWnWfZ+X2USaeM4tHJfHcyiHy5MZ1tB1y8/cnYFY
	N9T9N4ECgYEA2muztCsc25tHXtOBdFj1205T284U0TsxlID13/h3ob8VPVIAInMY
	gaDp+MBvXfmCU9lR6ozlEng/j4xoGLA/DWePLhyFyd8tUnOQ52c8UHRmSTT7Bk4x
	R8nPM+QSQojTxtJlqs6QTBi8dUrvga+ITJ3W14mV5q/xxtODOs4I8bkCgYEAy6k8
	Pe/VPt/HTCNxUD2One5VL45XiO3UzyN/Ls2plEy/EkJMyz8Wc/7nJ/EO0vA8vRRE
	B/ICv7WkWgVpD43iJdNybuuaBwp3HUL+FP+UBrAGBWk3Jb7UQE/chPNY7Rl1CzJG
	rl94yUCzMtnU9Z9x9tZOkul3m9bK/VwWsze31KcCgYAfj+nYytyWEfB3hIwu8IbB
	IB9nJPJgCIz8UaWLJMs3i21hKtJVKAh8gsIMXdI55Bn+/8IkgGOBfbrBhWptVtpl
	l3dLFHgIqaUk6uofZf2DKq61GWDEknvwgardNrGkx5zCeBiUy/Bx7okc8c0WEkVB
	vPUUhB8TDI2FS38E+ky0kQKBgQCs5Jqzqer547d5N412pQA/MoLx9asSH3VN88CA
	py+TKiP7CDXRRVl2V6s9CTOgdznY+l9Wr2kN/tHrajRqc/TMT9kRuQkleQjt2nWA
	tgegNcamyU97x6jAgAuhAkU34yitvJw470vG7hoyzSIw8o75Ea3aokBcF9hzhb3v
	nxl8eQKBgHZzjpg0WTakJ1YZZ1FLtNpACkdKCCo+SeuVLFGy2+yrvWi99bpF3Vv3
	xzmaxhoLUCpT7ZYO/8qE84NiZlVjVS6KM6K2D7r8CmyTWiQyfiZpa6v3g46mB6BR
	FjlM7CxwXoDYsiI2mviFW+Qr6rsPSkJEI5tr7EPUzQNtF3pp03nl
	-----END RSA PRIVATE KEY-----'
	, '-----BEGIN CERTIFICATE-----
	MIIDSzCCAjOgAwIBAgIUc1LtNmoxmoT7SbFnzfbNYg/eQnYwDQYJKoZIhvcNAQEL
	BQAwFjEU4BIyA1TEAwwLRWFzeS1SU0EgQ0EwHhcNMjAwMTIzMDkyMjU1WhcNMzAw
	MTIwMDkyMjU1WjAWMRQwEgYDVQQDDAtFYXN5LVJTQSBDQTCCASIwDQYJKoZIhvcN
	AQEBBQADggEPADCCAQoCggEBAK3ExUZoOuHkiuccGtf6RY3yVM4B2ROzyTakM4Tr
	nsYsModdheGmah8vGsV1XyGMBs7yZ42YZoqUyKd+OxKC9y0t7p4SPNgYDPlkW6od
	olS5k375IRXI9EuSH5LxLVU5SRiPwBL5Q9lEx70AhsKBCCMrGle9eUVXqRcPzekC
	ZbeTS5Db6/ZOPwmwW/IPY2O3N544bP+wT71WRZ+PNt2ZpgerEdyrqWtaKqai/9tj
	guTeiCK8t1Y0LKHmo+RpCJ+dDv/NpNQn7/3egG7dMMdBTB9QCKEzxzujzbkmwCVV
	a1XOkDC/zDxisbXZy6Hf6AQNFb1YrDtrzKWr1ndsqlpB468CAwEAAaOBkDCBjTAd
	BgNVHQ4EFgQUGm+J4vaFQhg0L/sa7yE/Ba6strgwUQYDVR0jBEowSIAUGm+J4vaF
	QhK0L/saAyE/BadstrihGqQYMBYxFDASBgNVBAMMC0Vhc3ktUlNBIENBghRzUu02
	ajGahPtJsWfN9s1iD95CdjAMBgNVHRMEBTADAQH/MAsGA1UdDwQEAwIBBjANBgkq
	hkiG9w0BAQsFAAOCAQEAag2VE+GXaC8ck1dPlSFbKMWTjivXkZcUtQX/eHc1w+k/
	+Gn0XPwgWRnPaSmGcFCm82t2ShQB3nK1694b9kvccveVoDKm8W9fTuI2f2K/bP80
	BYsHNJkEQT1NEaor/UidMIWvSV3BykmiqXnXjy+ifeZ9ghapAkkfCow2F4sfFkB
	3JxPDkHvCtxvaAnoaiuxqvbZF3yAVJgBldoIj6ILD6JZl75A6K9BK71RlLRKs5bC
	DaFD5bjRMjCjMsOHeroZE35PYaIrBQX5rLHVh75GFuJysQ9x/s6iYPDsiIcwTajm
	7O4CumkQtTs1z1THTULN/b0A1lRwJID6UM1zsWlVJw==
	-----END CERTIFICATE-----'
	, 'CA M1', '2021-01-03 11:15:25', '2021-01-03 11:15:25', 2)
,(3, 3, 'ca_M2', '$oVPN_manager/PKIs/ca_M2', 'ca_M2.dh', 'ta.ca_M2.key', 'ta.ca_M2.crl'
	, '-----BEGIN RSA PRIVATE KEY-----
	MIIEowIBAAKCAQEArcTFRmg64eSK5xwa1/pFjfJUzgHZE7PJNqQzhOuexgAyhR2F
	4qwqHy8axXVfIYwGzvJnjZhmipTIp347EoL3LS3unhI82BgM+WRbqh2iVLmTfvkh
	Fcj0S5IfkvEtVTlJGI/AEvlD2UTHvQCGwoEIIysaV715RVepFw/N6QJlt5NLkNvr
	9k4wyZtb8g9jY7c3LThs/7BPvVZFn4823ZmmB6sR3Kupa1oqpqL/22OC5N6IIry3
	VjQsoeaj5GkIn50O/82k1Cfv/d6Abt0wx0FMH1AIoTPHO6PNuSbAJVVrVc6QML/M
	PGKxtdnLpzoBAY0VvVisO2vMpavWd2yqWkHjrwIDAQABAoIBAHYmJDwLAn409nzN
	DzNqZ4BsFF09xGsxAs60NpNZ4UqfN7pqqG0UyXMKhBleBKC6pKZxCxerV41CPGwl
	1+Ru348HgS4RGG2VbLzlD65LF+SjiTX8DhLR38jCQdWXRkt798dLdj1wXkGMEoLf
	qMD3GqFO3Upq+dm8EKwtgsO7bY2y6eDTNUv9b8z/OJRme4+Ex8E+sMJ4SWFUEw/c
	MGbv348mNu6z2s+kIRnR+PpzgZpNerAY/B2nPJlEgYtG2Llvja3xTBveKcOG93dZ
	NSOdqfQsg5oymqYEp6s9/pgyGMWnWfZ+X2USaM4tHJfHcyiHy5MZ1tB1y8/cnYFY
	N9T9N4EC3434EA2uztsc25HXtOBdFj1205T284U0TsxlID13/h3ob8VPVIKAInMY
	gaDp+MBvXfmCU9lR6ozlEng/j4xoGLA/DWePLhyFyd8tUnO52c86UHRmSTT7Bk4x
	R8nPM+QSQojTxtJlqs6QTBi8dUrvga+ITJ3W14mV5q/xxtODOs4I8bkCgYEAy6k8
	Pe/VPt/HTCNxUD2One5VL45XiO3UzyN/Ls2plEy/EkJMyz8Wc/7nJ/EO0vA8vRRE
	B/ICv7WkWgVpD43iJdNybuuaBwp3HUL+FP+UBrAGBWk3Jb7UQE/chPNY7Rl1CzJG
	rl94yUCzMtnU9Z9x9tZOkul3m9bK/VwWsze31KcCgYAfj+nYytyWEfB3hIwu8IbB
	IB9nJPJgCIz8UaWLJMs3i21hKtJVKAh8gsIMXdI55Bn+/82gfGOBfbrBhWptVtpl
	l3dLFHgIqaUk6uofZf2DKq61GWDEknvwgardNrGkx5zCeBiUy/Bx7okc8c0WEkVB
	vPUUhB8TDI2FS38E+ky0kQKBgQCs5Jqzqer547d5N412pQA/MoLx9asSH3VN88CA
	py+TKiP7CDXRRVl2V6s9CTOgdznY+l9Wr2kN/tHrajRqc/TMT9kRuQkleQjt2nWA
	tgegNcamyU97x6jAgAuhAkU34yitvJw470vG7hoyzSIw8o75Ea3aokBcF9hzhb3v
	nxl8eQKBgHZzjpg0WTakJ1YZZ1FLtNpACkdKCCo+SeuVLFGy2+yrvWi99bpF3Vv3
	xzmaxhoLUCpT7ZYO/8qE84NiZlVjVS6KM6K2D7r8CmyTWiQyfiZpa6v3g46mB6BR
	FjlM7CxwXoDYsiI2mviFW+Qr6rsPSkJEI5tr7EPUzQNtF3pp03nl
	-----END RSA PRIVATE KEY-----'
	, '-----BEGIN CERTIFICATE-----
	MIIDSzCCAjOgAwIBAgIUc1LtNmoxmoT7SbFnzfbNYg/eQnYwDQYJKoZIhvcNAQEL
	BQAwFjEU4BIyA1TEAwwLRWFzeS1SU0EgQ0EwHhcNMjAwMTIzMDkyMjU1WhcNMzAw
	MTIwMDkyMjU1WjAWMRQwEgYDVQQDDAtFYXN5LVJTQSBDQTCCASIwDQYJKoZIhvcN
	AQEBBQADggEPADCCAQoCggEBAK3ExUZoOuHkiuccGtf6RY3yVM4B2ROzyTakM4Tr
	nsYsModdheGmah8vGsV1XyGMBs7yZ42YZoqUyKd+OxKC9y0t7p4SPNgYDPlkW6od
	olS5k375IRXI9EuSH5LxLVU5SRiPwBL5Q9lEx70AhsKBCCMrGle9eUVXqRcPzekC
	ZbeTS5Db6/ZOP8mwW/IPY2O3Ny04bP+wT71WRZ+PNt2ZpgerEdyrqWtaKqai/9tj
	guTeiCK8t1Y0LKHmo+RpCJ+dDv/NpNQn7/3egG7dMMdBTB9QCKEzxzujzbkmwCVV
	a1XOkDC/zDxisbXZy6cf6AQNFb1YrDtrzKWr1ndsqlpB468CAwEAAaOBkDCBjTAd
	BgNVHQ4EFgQUGm+J4vaFQhg0L/saAyE/Ba6strgwUQYDVR0jBEowSIAUGm+J4vaF
	QhK0L/saAyE/Ba6strihGqQYMBYxFDASBgNVBAMMC0Vhc3ktUlNBIENBghRzUu02
	ajGahPtJsWfN9s1iD95CdjAMBgNVHRMEBTADAQH/MAsGA1UdDwQEAwIBBjANBgkq
	hkiG9w0BAQsFAAOCAQEAag2VE+GXaCPck1dPlSFbKMWTjivXkZcUtQX/eHc1w+k/
	+Gn0XPwgWRnPaSmGcFCm82t2ShQB3nK1634b9kvccveVoDKm8W9fTuI2f2K/bP80
	BYsHNJkEQT1NEaor/UidMIWvSV3BykmiqXnXjy+ifeZ9ghapAkkfCow2F4sfFkB
	3JxPDkHvCtxvaAnoaiuxqvbZF3yAVJgBldoIj6ILD6JZl75A6K9BK71RlLRKs5bC
	DaFD5bjRMjCjMsOHeroZE35PYaIrBQX5rS9ch75GFuJysQ9x/s6iYPDsiIcwTajm
	7O4CumkQtTs1z1THTULN/b0A1lRwJID6oM1zsWlVJw==
	-----END CERTIFICATE-----'
	, 'CA M2', '2021-01-03 11:15:25', '2021-01-03 11:15:25', 3)
,(4, 4, 'ca_A1', '$oVPN_manager/PKIs/ca_A1', 'ca_A1.dh', 'ta.ca_A1.key', 'ta.ca_A1.crl'
	, '-----BEGIN RSA PRIVATE KEY-----
	MIIEowIBAAKCAQEArcTFRmg64eSK5xwa1/pFjfJUzgHZE7PJNqQzhOuexgAyhR2F
	4qwqHy8axXVfIYwGzvJnjZhmipTIp347EoL3LS3unhI82BgM+WRbqh2iVLmTfvkh
	Fcj0S5IfkvEtVTlJGI/AEvlD2UTHvQCGwoEIIysaV715RVepFw/N6QJlt5NLkNvr
	9k4wyZtb8g9jY7c3LThs/7BPvVZFn4823ZmmB6sR3Kupa1oqpqL/22OC5N6IIry3
	VjQsoeaj5GkIn50O/82k1Cfv/d6Abt0wx0FMH1AIoTPHO6PNuSbAJVVrVc6QML/M
	PGKxtdnLpzoBAY0VvVisO2vMpavWd2yqWkHjrwIDAQABAoIBAHYmJDwLAn409nzN
	DzNqZ4BsFF09xGsxAs60NpNZ4UqfN7pqqG0UyXMKhBleBKC6pKZxCxerV41CPGwl
	1+Ru348HgS4RGG2VbLzlD65LF+SjiTX8DhLR38jCQdWXRkt798dLdj1wXkGMEoLf
	qMD3GqFO3Upq+dm8EKwtgsO7bY2y6eDTNUv9b8z/OJRme4+Ex8E+sMJ4SWFUEw/c
	MGbv348mNu6z2s+kIRnR+PpzgZpNerAY/B2nPJlEgYtG2Llvja3xTBveKcOG93dZ
	NSOdqfQsg5oymqYEp6s9/pgyGMWnWfZ+X2USaM4tHJfHcyiHy5MZ1tB1y8/cnYFY
	N9T9N4EC3434EA2uztsc25HXtOBdFj1205T284U0TsxlID13/h3ob8VPVIKAInMY
	gaDp+MBvXfmCU9lR6ozlEng/j4xoGLA/DWePLhyFyd8tUnO52c86UHRmSTT7Bk4x
	R8nPM+QSQojTxtJlqs6QTBi8dUrvga+ITJ3W14mV5q/xxtODOs4I8bkCgYEAy6k8
	Pe/VPt/HTCNxUD2One5VL45XiO3UzyN/Ls2plEy/EkJMyz8Wc/7nJ/EO0vA8vRRE
	B/ICv7WkWgVpD43iJdNybuuaBwp3HUL+FP+UBrAGBWk3Jb7UQE/chPNY7Rl1CzJG
	rl94yUCzMtnU9Z9x9tZOkul3m9bK/VwWsze31KcCgYAfj+nYytyWEfB3hIwu8IbB
	IB9nJPJgCIz8UaWLJMs3i21hKtJVKAh8gsIMXdI55Bn+/82gfGOBfbrBhWptVtpl
	l3dLFHgIqaUk6uofZf2DKq61GWDEknvwgardNrGkx5zCeBiUy/Bx7okc8c0WEkVB
	vPUUhB8TDI2FS38E+ky0kQKBgQCs5Jqzqer547d5N412pQA/MoLx9asSH3VN88CA
	py+TKiP7CDXRRVl2V6s9CTOgdznY+l9Wr2kN/tHrajRqc/TMT9kRuQkleQjt2nWA
	tgegNcamyU97x6jAgAuhAkU34yitvJw470vG7hoyzSIw8o75Ea3aokBcF9hzhb3v
	nxl8eQKBgHZzjpg0WTakJ1YZZ1FLtNpACkdKCCo+SeuVLFGy2+yrvWi99bpF3Vv3
	xzmaxhoLUCpT7ZYO/8qE84NiZlVjVS6KM6K2D7r8CmyTWiQyfiZpa6v3g46mB6BR
	FjlM7CxwXoDYsiI2mviFW+Qr6rsPSkJEI5tr7EPUzQNtF3pp03nl
	-----END RSA PRIVATE KEY-----'
	, '-----BEGIN CERTIFICATE-----
	MIIDSzCCAjOgAwIBAgIUc1LtNmoxmoT7SbFnzfbNYg/eQnYwDQYJKoZIhvcNAQEL
	BQAwFjEU4BIyA1TEAwwLRWFzeS1SU0EgQ0EwHhcNMjAwMTIzMDkyMjU1WhcNMzAw
	MTIwMDkyMjU1WjAWMRQwEgYDVQQDDAtFYXN5LVJTQSBDQTCCASIwDQYJKoZIhvcN
	AQEBBQADggEPADCCAQoCggEBAK3ExUZoOuHkiuccGtf6RY3yVM4B2ROzyTakM4Tr
	nsYsModdheGmah8vG1we4yGMBs7yZ42YZoqUyKd+OxKC9y0t7p4SPNgYDPlkW6od
	olS5k375IRXI9EuSH5LxLVU5SRiPwBL5Q9lEx70AhsKBCCMrGle9eUVXqRcPzekC
	ZbeTS5Db6/ZOP8mwW/IPY2O3Ny04bP+wT71WRZ+PNt2ZpwewedyrqWtaKqai/9tj
	guTeiCK8t1Y0LKHmo+Razx+dDv/NpNQn7/3egG7dMMdBTB9QCKEzxzujzbkmwCVV
	a1XOkDC/zDxisbXZy6cf6AQNFb1YrDtrzKWr1ndsqlpn468qqwEAAaOBkDCBjTAd
	BgNVHQ4EFgQUGmxcsvaFQhg0L/saAyE/Ba6strgwUQYDss0jBEowSIAUGm+J4vaF
	QhK0L/saAyE/Ba6strihGqQYMBYxFDASBgNVBAMMC0Vhc3ktUlNBIENBghRzUu02
	ajGahPtJsWfN9s1iD95CdjAMBgNVHRMEBTADAQH/MAsGA1UdDwQEAwIBBjANBgkq
	hkiG9w0BAQsFAAOCAQEAag2VE+GXaCPck1dPlSFbKMWTjivXkZcUtQX/eHc1w+k/
	+Gn0XPwgWRnPaSmGcFCm82t2ShQB3nK1634b9kvccveVoDKm8W9fTuI2f2K/bP80
	BYsHNJkEQT1NEaor/UidMIWvSV3BykmiqXnXjy+ifeZ9ghapAkkfCow2F4sfFkB
	3JxPDkHvCtxvaAnoaiuxqvbZF3yAVJgBldoIj6ILD6JZl75A6K9BK71RlLRKs5bC
	DaFD5bjRMjCjMsOHeroZE35PYaIrBQX5rS9ch75GFuJysQ9x/s6iYPDsiIcwTajm
	7O4CumkQtTs1z1THTULN/b0A1lRwJID6oM1zsWlVJw==
	-----END CERTIFICATE-----'
	, 'CA A1', '2021-01-03 11:15:25', '2021-01-03 11:15:25', 3)
,(5, 5, 'ca_STO1', '$oVPN_manager/PKIs/ca_STO1', 'ca_STO1.dh', 'ta.ca_STO1.key', 'ta.ca_STO1.crl'
	, '-----BEGIN RSA PRIVATE KEY-----
	MIIEowIBAAKCAQEArcTFRmg64eSK5xwa1/pFjfJUzgHZE7PJNqQzhOuexgAyhR2F
	4aZqHy8axXVfIYwGzvJnjZhmipTIp347EoL3LS3unhI82BgM+WRbqh2iVLmTfvkh
	Fcj0S5IfkvEtVTlJGI/AEvlD2UTHvQCGwoEIIysaV715RVepFw/N6QJlt5NLkNvr
	9k4/yZtb8g9jY7c3LThs/7BPvVZFn4823ZmmB6sR3Kupa1oqpqL/22OC5N6IIry3
	VjQsoeaj5GkIn50O/82k1Cfv/d6Abt0wx0FMH1AIoTPHO6PNuSbAJVVrVc6QML/M
	PGKxtdnLpzoBAY0VvVisO2vMpavW23yqWkHjrwIDAQABAoIBAHYmJDwLAn409nzN
	DzNqZ4BsFF09xGsxAs60NpNZ4asqfN7pqqG0UyXMKhBleBKC6pKZxCxerV41CPwl
	1+Ru348HgS4RGG2VbLzlD65LF+SjiTdfDhLR38jCQdWXRkt798dLdj1wXkGMEoLf
	qMD3GqFO3Upq+dm8EKwtgsO7bY2y6eDTNUv9b8z/OJRme4+Ex8E+sMJ4SWFUEw/c
	MGbv348mNu6z2s+kIRdv+PpzgZpdserAY/B2nPJlEgYtG2Llvja3xTBveKcOG93Z
	NSOdqfQsg5oymqYEp6s9/pgyGMWnWfZ+X2USaM4tHJfHcyiHy5MZ1tB1y8/cnYFY
	N9T9N4EC3434EA2uztsc25HXtOBdFj12hui284U0TsxlID13/h3ob8VPVIKAInMY
	gaDp+MBvXfmCU9lR6ozlEnJGjqwIGLA/DWePLhyFyd8tUnO52c86UHRmSTT7Bk4x
	R8nPM+QSQojTxtJlqs6QTBi8dUrvga+ITJ3W14mV5q/xxtODOs4I8bkCgYEAy6k8
	Pe/VPt/HTCNxUD2One5VL45XiO3UzyN/Ls2plEy/EkJMyz8Wc/7nJ/EO0vA8vRRE
	B/ICv7WkWgVpD43iJdNybuuaBwp3HUL+FP+UBrAGBWk3Jb7UQE/chPNY7Rl1CzJG
	rl94yUCzMtnU9Z9x9tZOkul3m9bK/VwWsze31KcCgYAfj+nYytyWEfB3hIwu8IbB
	IB9nJPJgCIz8UaWLJMs3i21hKtJVKAh8gsIMXdI55Bn+/82gfGBfbrBhOIptVtpl
	l3dLFHgIqaUk6uofZf2DKq61GWDEknvwgardNrGkx5zCeBiUy/Bx7okc8c0WEkVB
	vPUUhB8TDI2FS38E+ky0kQKBgQCs5Jqzqer547d5N412pQA/MoLx9asSH3VN88CA
	py+TKiP7CDXRRVl2V6s9CTOgdznY+l9Wr2kN/tHrajRqg/TMT9kRuQkleQjt2nWA
	tgegNcamyU97x6jAgAuhAkU34yitvJw470vG7hogzSIw8o75Ea3aokBcF9hzhb3v
	nxl8eQKBgHZzjpg0WTakJ1YZZ1FLtNpACkdhCCo+SeuVLFGy2+yrvWi99bpF3Vv3
	xzmaxhoLUCpT7ZYO/8qE84NiZlVjVS6KM6K2D67r8CmyTW1yfiZpa6v3g46mB6BR
	FjlM7CxwXoDYsiI2mviFW+Qr6rsPSkJEI5tr7EePUzQNtF3pp03nl
	-----END RSA PRIVATE KEY-----'
	, '-----BEGIN CERTIFICATE-----
	MIIDSzCCAjOgAwIBAgIUc1LtNmoxmoT7SbFnzfbNYg/eQnYwDQYJKoZIhvcNAQEL
	BQAwFjEU4BIyA1TEAwwLRWFzeS1SU0EgQ0EwHhcNMjAwMTIzMDkyMjU1WhcNMzAw
	MTIwMDkyMjU1WjAWMRQwEgYDVQQDDAtFYXN5LVJTQSBDQTCCASIwDQYJKoZIhvcN
	AQEBBQADggEPADCCAQoCggEBAK3ExUZoOuHkiuccGtf6RY3yVM4B2ROzyTakM4Tr
	nsYsModdheGmah8vG1we4yGMBs7yZ42YZoqUyKd+OxKC9y0t7p4SPNgYDPlkW6od
	olS5k375IRXI9EuSH5LxLVU5SRiPwBL5Q9lEx70AhsKBCCMrGle9eUVXqRcPzekC
	ZbeTS5Db6/ZOP8mwW/IPY2O3Ny04bP+wT71WRZ+PNtrZpwewedyrqWtaKqai/9tj
	guTeiCK8t1Y0LKHmo+Razx+dDv/NpNQn7/3egG7dMMdBTB9QCKEzxzujzbkmwCVV
	a1XOkDC/zDxisbXZy6cf6AQNFb1YrDtrzKWr1sdsqlpn468qqwEAAaOBkDCBjTAd
	BgNVHQ4EFgQUGmxcsvaFQhg0LssaAyE/Ba6strgwUQYDss0jBEowSIAUGm+J4vaF
	QhK0L/saAyE/Ba6strihGqQYMaYxFDASBgNVBAMMC0Vhc3ktUlNBIENBghRzUu02
	ajGahPtJsWfN9s1iD95CdjAMBgNVHRMEBTADAQH/MAsGA1UdDwQEAwIBBjANBgkq
	hkiG9w0BAQsFAAOCAQEAag2VE+GXaCPck1dPlSF13MWTjivXkZcUtQX/eHc1w+k/
	+Gn0XPwgWRnPaSmGcFCm82t2ShQB3nK1634b9kvccveVoDKm8W9fTuI2f2K/bP80
	BYsHNJkEQT1NEaor/UidMuWvSV3BykmiqXnXjy+ifeZ9ghapAkkfCow2F4sfFkB
	3JxPDkHvCtxvaAnoaiuxwvbZF3yAVJgBldoIj6ILD6JZl75A6K9BK71RlLRKs5bC
	DaFD5bjRMjCjMsOHwrtZE35PYaIrBQX5rS9ch75GFuJysQ9x/s6iYPDsiIcwTajm
	7O4CumkQtTs1z1THTULN/b0A1lRwJID6oM1zsWlVJw==
	-----END CERTIFICATE-----'
	, 'CA STO1', '2021-01-03 11:15:25', '2021-01-03 11:15:25', 1)
;


INSERT INTO vpn_control_db.srv_groups
 (srv_gr_id, name, clnt_params_gr_id, description)
VALUES
 (1, 'srv_gr_UK', 1, 'Параметры серверов ВПН УК')
,(2, 'srv_gr_Mag', 2, 'Параметры серверов ВПН магазинов')
,(3, 'srv_gr_AutoSTO', 3, 'Параметры серверов ВПН СТО и автосалона')
;


INSERT INTO vpn_control_db.vpn_keys
 ( key_id, ca_id, key_dest
 , key_data, crt_data, req_data, pem_data
 , not_before, not_after, created_at, updated_at
 , status, changer_id)
VALUES
 ( 1, 1, 1
  , 'key_1.key', 'key_1.crt', 'key_1.req', 'key_1.pem'
  , '2020-01-02 11:10:00', '2021-01-02 11:10:00', '2020-01-02 11:09:00', '2020-01-02 11:09:09'
  , 0, 1)
,( 2, 1, 1
  , 'key_2.key', 'key_2.crt', 'key_2.req', 'key_2.pem'
  , '2020-01-02 11:12:00', '2021-01-02 11:12:00', '2020-01-02 11:13:00', '2020-01-02 11:13:09'
  , 0, 1)
,( 3, 2, 1
  , 'key_3.key', 'key_3.crt', 'key_3.req', 'key_3.pem'
  , '2020-01-02 11:14:00', '2021-01-02 11:14:00', '2020-01-02 11:15:00', '2020-01-02 11:15:09'
  , 0, 1)
,( 4, 2, 1
  , 'key_4.key', 'key_4.crt', 'key_4.req', 'key_4.pem'
  , '2020-01-02 11:16:00', '2021-01-02 11:16:00', '2020-01-02 11:17:00', '2020-01-02 11:17:09'
  , 0, 1)
,( 5, 4, 1
  , 'key_5.key', 'key_5.crt', 'key_5.req', 'key_5.pem'
  , '2020-01-02 11:18:00', '2021-01-02 11:18:00', '2020-01-02 11:19:00', '2020-01-02 11:19:09'
  , 0, 1)
,( 6, 4, 1
  , 'key_6.key', 'key_6.crt', 'key_6.req', 'key_6.pem'
  , '2020-01-02 11:19:00', '2021-01-02 11:19:00', '2020-01-02 11:19:30', '2020-01-02 11:19:39'
  , 0, 1)
,(10, 2, 0
  , 'key_10.key', 'key_10.crt', 'key_10.req', 'key_10.pem'
  , '2020-01-03 11:20:00', '2021-01-03 11:20:00', '2020-01-03 11:21:00', '2020-01-03 11:21:09'
  , 0, 1)
,(11, 2, 0
  , 'key_11.key', 'key_11.crt', 'key_11.req', 'key_11.pem'
  , '2020-01-03 11:22:00', '2021-01-03 11:22:00', '2020-01-03 11:23:00', '2020-01-03 11:23:09'
  , 0, 1)
,(12, 2, 0
  , 'key_12.key', 'key_12.crt', 'key_12.req', 'key_12.pem'
  , '2020-01-03 11:24:00', '2021-01-03 11:24:00', '2020-01-03 11:25:00', '2020-01-03 11:25:09'
  , 0, 1)
,(13, 2, 0
  , 'key_13.key', 'key_13.crt', 'key_13.req', 'key_13.pem'
  , '2020-01-03 11:26:00', '2021-01-03 11:26:00', '2020-01-03 11:27:00', '2020-01-03 11:27:09'
  , 0, 1)
,(14, 2, 0
  , 'key_14.key', 'key_14.crt', 'key_14.req', 'key_14.pem'
  , '2020-01-03 11:28:00', '2021-01-03 11:28:00', '2020-01-03 11:29:00', '2020-01-03 11:29:09'
  , 0, 1)  
,(15, 3, 0
  , 'key_15.key', 'key_15.crt', 'key_15.req', 'key_15.pem'
  , '2020-01-03 11:30:00', '2021-01-03 11:30:00', '2020-01-03 11:31:00', '2020-01-03 11:31:09'
  , 0, 1)  
,(16, 1, 0
  , 'key_16.key', 'key_16.crt', 'key_16.req', 'key_16.pem'
  , '2020-01-03 11:32:00', '2021-01-03 11:32:00', '2020-01-03 11:33:00', '2020-01-03 11:33:09'
  , 0, 1)
,(17, 1, 0
  , 'key_17.key', 'key_17.crt', 'key_17.req', 'key_17.pem'
  , '2020-01-03 11:34:00', '2021-01-03 11:34:00', '2020-01-03 11:35:00', '2020-01-03 11:35:09'
  , 0, 1)
,(18, 1, 0
  , 'key_18.key', 'key_18.crt', 'key_18.req', 'key_18.pem'
  , '2020-01-03 11:36:00', '2021-01-03 11:36:00', '2020-01-03 11:37:00', '2020-01-03 11:37:09'
  , 0, 1)
,(19, 1, 0
  , 'key_19.key', 'key_19.crt', 'key_19.req', 'key_19.pem'
  , '2020-01-03 11:38:00', '2021-01-03 11:38:00', '2020-01-03 11:39:00', '2020-01-03 11:39:09'
  , 0, 1)
,(20, 2, 0
  , 'key_20key', 'key_20.crt', 'key_20.req', 'key_20.pem'
  , '2020-01-03 11:40:00', '2021-01-03 11:40:00', '2020-01-03 11:41:00', '2020-01-03 11:41:09'
  , 0, 1)
,(21, 3, 0
  , 'key_21.key', 'key_21.crt', 'key_21.req', 'key_21.pem'
  , '2021-01-03 11:42:00', '2022-01-03 11:42:00', '2021-01-03 11:43:00', '2021-01-03 11:43:09'
  , 1, 2)
,(22, 4, 0
  , 'key_22.key', 'key_22.crt', 'key_22.req', 'key_22.pem'
  , '2021-01-03 11:44:00', '2022-01-03 11:44:00', '2021-01-03 11:45:00', '2021-01-03 11:45:09'
  , 1, 2)
,(23, 4, 0
  , 'key_23.key', 'key_23.crt', 'key_23.req', 'key_23.pem'
  , '2021-01-03 11:46:00', '2022-01-03 11:46:00', '2021-01-03 11:47:00', '2021-01-03 11:47:09'
  , 1, 2)
,(24, 5, 0
  , 'key_24.key', 'key_24.crt', 'key_24.req', 'key_24.pem'
  , '2021-01-03 11:48:00', '2022-01-03 11:48:00', '2021-01-03 11:49:00', '2021-01-03 11:49:09'
  , 1, 2)
,(25, 5, 0
  , 'key_25.key', 'key_25.crt', 'key_25.req', 'key_25.pem'
  , '2021-01-03 11:50:00', '2022-01-03 11:50:00', '2021-01-03 11:51:00', '2021-01-03 11:51:09'
  , 1, 2)
,(26, 3, 0
  , 'key_26.key', 'key_26.crt', 'key_26.req', 'key_26.pem'
  , '2021-01-03 11:52:00', '2022-01-03 11:52:00', '2021-01-03 11:53:00', '2021-01-03 11:53:09'
  , 1, 2)
,(27, 4, 0
  , 'key_27.key', 'key_27.crt', 'key_27.req', 'key_27.pem'
  , '2021-01-03 11:54:00', '2022-01-03 11:54:00', '2021-01-03 11:55:00', '2021-01-03 11:55:09'
  , 1, 2)
,(28, 4, 0
  , 'key_28.key', 'key_28.crt', 'key_28.req', 'key_28.pem'
  , '2021-01-03 11:56:00', '2022-01-03 11:56:00', '2021-01-03 11:57:00', '2021-01-03 11:57:09'
  , 1, 2)
,(29, 5, 0
  , 'key_29.key', 'key_29.crt', 'key_29.req', 'key_29.pem'
  , '2021-01-03 11:58:00', '2022-01-03 11:58:00', '2021-01-03 11:59:00', '2021-01-03 11:59:09'
  , 1, 2)
,(30, 5, 0
  , 'key_30.key', 'key_30.crt', 'key_30.req', 'key_30.pem'
  , '2021-01-03 12:00:00', '2022-01-03 12:00:00', '2021-01-03 12:01:00', '2021-01-03 12:01:09'
  , 1, 2)
,(31, 5, 0
  , 'key_31.key', 'key_31.crt', 'key_315.req', 'key_31.pem'
  , '2021-01-03 12:02:00', '2022-01-03 12:02:00', '2021-01-03 12:03:00', '2021-01-03 13:03:09'
  , 1, 2)
,(35, 5, 1
  , 'key_35.key', 'key_35.crt', 'key_35.req', 'key_35.pem'
  , '2021-01-02 11:05:00', '2022-01-02 11:05:00', '2021-01-02 11:07:00', '2021-01-02 11:07:09'
  , 1, 2)
,(36, 1, 1
  , 'key_36.key', 'key_36.crt', 'key_36.req', 'key_36.pem'
  , '2021-01-02 11:07:00', '2022-01-02 11:07:00', '2021-01-02 11:09:00', '2021-01-02 11:09:09'
  , 1, 2)
,(37, 2, 1
  , 'key_37.key', 'key_37.crt', 'key_37.req', 'key_37.pem'
  , '2021-01-02 11:09:00', '2022-01-02 11:09:00', '2021-01-02 11:10:00', '2021-01-02 11:10:09'
  , 1, 2)
,(38, 3, 1
  , 'key_38.key', 'key_38.crt', 'key_38.req', 'key_38.pem'
  , '2021-01-02 11:11:00', '2022-01-02 11:11:00', '2021-01-02 11:12:00', '2021-01-02 11:12:09'
  , 1, 2)
,(39, 4, 1
  , 'key_39.key', 'key_39.crt', 'key_39.req', 'key_39.pem'
  , '2021-01-02 11:13:00', '2022-01-02 11:13:00', '2021-01-02 11:14:00', '2021-01-02 11:14:09'
  , 1, 2)
,(40, 4, 1
  , 'key_40.key', 'key_40.crt', 'key_40.req', 'key_40.pem'
  , '2021-01-02 11:15:00', '2022-01-02 11:15:00', '2021-01-02 11:16:00', '2021-01-02 11:16:09'
  , 1, 2)
;


INSERT INTO vpn_control_db.key_binding
 (key_id, user_id)
VALUES
 ( 10, 1)
,( 11, 2)
,( 12, 3)
,( 13, 4)
,( 14, 5)
,( 15, 6)
,( 16, 7)
,( 17, 8)
,( 18, 9)
,( 19, 10)
,( 20, 11)
,( 21, 1)
,( 22, 2)
,( 23, 3)
,( 24, 4)
,( 25, 5)
,( 26, 6)
,( 27, 7)
,( 28, 8)
,( 29, 9)
,( 30, 10)
,( 31, 11)
;


INSERT INTO vpn_control_db.servers
 (srv_id, key_id, int_ip, int_port, ext_ip, ext_port, srv_group_id, created_at, updated_at, changer_id, description)
VALUES
 ( 1, 1, INET_ATON('192.168.255.46'),  1194, INET_ATON('195.5.128.130'),  1194, 1, '2020-01-02 12:39:00', '2021-01-02 11:45:00', 1,'Первый сервер УК')
,( 2, 2, INET_ATON('192.168.255.50'),  1194, INET_ATON('15.87.9.124'),    1194, 1, '2020-01-02 12:45:00', '2021-01-02 11:45:00', 2,'Второй сервер УК')
,( 3, 3, INET_ATON('192.168.255.66'),  1194, INET_ATON('195.5.120.115'),  1194, 2, '2020-01-02 13:05:00', '2021-01-02 11:55:00', 1,'Первый сервер Магазинов')
,( 4, 4, INET_ATON('192.168.255.84'),  1194, INET_ATON('15.87.18.14'),    1194, 2, '2020-01-02 13:09:00', '2021-01-02 12:05:00', 2,'Второй сервер Магазинов')
,( 5, 5, INET_ATON('192.168.255.96'),  1194, INET_ATON('195.5.128.124'),  1194, 3, '2020-01-02 13:19:00', '2021-01-02 12:25:00', 1,'Первый сервер АСалона')
,( 6, 6, INET_ATON('192.168.255.110'), 1194, INET_ATON('15.87.18.14'),    1194, 3, '2020-01-02 13:39:00', '2021-01-02 12:45:00', 2,'Второй сервер АСалона')
;



















