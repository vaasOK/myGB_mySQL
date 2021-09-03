
/*
 *
 * БД для администрирования системы удалённого доступа на основе OpenVPN
 * 
 **/


-- 1. пользователи 
 users
    - id
    - surname
    - name
    - middle_name
    - base_doc_url      -- ссылка на заявку - основание для создания пользователя
    - status            -- active | paused | blocked | deleted
    - created_at
    - updated_at

-- 2. организации
 organizations
    - id
    - name
    - full_name
    - main_contact      -- users_id 
    - description


-- 3. профили пользователей
 user_profiles
    - user_id
    - user_categorys_id
    - organizations_id
    - clnt_params_gr_id
    - description

    
    
    
-- 4. контакты организаций
 org_contacts
    - organizations_id
    - user_profiles_id
    - description



-- 5. PKI, центры сертификации
 
 PKIs
 	- id        	-- id Центра сертификации
 	- organizations_id
 	- ca_name       
 	- ca_file_path
 	- ca_key
 	- ca_crt
 	- ca_dh
 	- ca_crl
 	- ta_key
 	
 
-- 6. ключи
 keys
        - id
        - key_dest          -- user | server
        - priv
        - crt
        - req
        - created_at
        - not_before
        - not_after
        - status            -- active | revoked

        
-- 7. привязка ключей
 key_binding
        - keys_id           -- uniq
        - users_id      

        
-- 8. Серверы OpenVPN
 servers
        - id
        - keys_id
        - int_ip
        - int_port
        - ext_ip
        - ext_port
        - srv_groups_id
        - description
        

-- 9. Servers group
 srv_groups
        - id
        - srv_params_file
        - description
        

    
-- 10. email's 
 emails
        - id
        - user_id
        - address
        - description
        - created_at
        - updated_at
    
 
-- 11. phones 
 phones
        - id
        - user_id
        - number
        - description
        - created_at
        - updated_at
    

-- 12. категории пользователей      
 user_categorys
        - id
        - name
        - role        -- normal | VIP | security | org_admin | sys_admin

  
-- 13. группа параметров клиентов (пользовательских программ)
 clnt_params_gr
        - id
        - name
        - description
        - params_file
 

 

    
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
    При окончании срока действия ключа – кидать на привязанный e-mail оповещения/предупреждения, за какой-то срок (месяц/пара недель/последняя неделя - ежедневно)
    Добавить в админку возможность экспорта списка ключей / пользователей (типа отчёт)
    Администрирование админки – пользователи, права, и т.д. – обговариваемо… (чтобы запустить сюда СБ – пусть сами смотрят кто и что и сами себе отчёты генерят)

*/
