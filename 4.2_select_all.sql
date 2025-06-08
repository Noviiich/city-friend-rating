-- Вывести имя пользователя, кол-во очков, место пользователя в общем рейтинге, в рейтинге по его городу и среди его друзей
WITH target_user AS (
    SELECT id, username, city, points
    FROM users
    WHERE username = 'user123' -- Замените на нужного пользователя
)
SELECT
    tu.username,
    tu.points,
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