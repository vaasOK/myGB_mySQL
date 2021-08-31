-- CROSS JOIN
SELECT *
FROM users u, messages m -- плохой тон, перечисление таблиц через запятую
;

SELECT *
FROM users 
CROSS JOIN messages			-- плохой тон, простой CROSS JOIN
WHERE users.id = messages.from_user_id
;

-- INNER JOIN
selSELECTect *
FROM users 
INNER JOIN messages on users.id = messages.from_user_id
;

-- LEFT OUTER JOIN
SELECT users.*, messages.*
FROM users 
LEFT OUTER JOIN messages on users.id = messages.from_user_id
WHERE messages.id is NULL 
ORDER BY messages.id 
;
 
-- RIGHT OUTER JOIN
SELECT users.*, messages.*
FROM  messages
RIGHT OUTER JOIN users on users.id = messages.from_user_id
WHERE messages.id is NULL 
ORDER BY messages.id 
;

-- FULL OUTER JOIN
SELECT users.*, messages.*
FROM users 
LEFT OUTER JOIN messages on users.id = messages.from_user_id
	UNION 
SELECT users.*, messages.*
FROM users 
RIGHT OUTER JOIN messages on users.id = messages.from_user_id
; 