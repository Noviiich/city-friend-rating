--Общий рейтинг пользователя, рейтинг по его городу и среди его друзей.(1-2s)
WITH target_user AS (
    SELECT id, city, points
    FROM users
    WHERE username = 'user123' -- Замените на нужного пользователя
)
SELECT
    -- Глобальный ранг
    (SELECT COUNT(*) FROM users u2 WHERE u2.points > tu.points) + 1 AS global_rank,
    -- Рейтинг в городе
    (SELECT COUNT(*) FROM users u3 WHERE u3.city = tu.city AND u3.points > tu.points) + 1 AS city_rank,
    -- Рейтинг друзей
    (SELECT COUNT(*) + 1 FROM (
        SELECT u.points
        FROM friends f
        JOIN users u ON f.friend_id = u.id
        WHERE f.user_id = tu.id
        UNION ALL
        SELECT points FROM target_user
    ) fd WHERE fd.points > tu.points) AS friends_rank
FROM target_user tu;

-- Топ N пользователей по общему рейтингу (1ms)
SELECT id, username, points
FROM users
ORDER BY points DESC
LIMIT 100;

-- Топ N пользователей в указанном городе(1ms)
SELECT id, username, points
FROM users
WHERE city = 'Москва' -- Подставить нужный город
ORDER BY points DESC
LIMIT 100;

--  Топ N друзей указанного пользователя (14ms)
WITH target_user AS (
    SELECT id
    FROM users
    WHERE username = 'user1234' -- Имя целевого пользователя
    LIMIT 1
)
SELECT 
    u.id, 
    u.username, 
    u.points
FROM friends f
JOIN users u ON f.friend_id = u.id
WHERE f.user_id = (SELECT id FROM target_user)
ORDER BY u.points DESC
LIMIT 100;