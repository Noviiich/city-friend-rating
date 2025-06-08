-- Индекс для более быстрого выполнения поиска
CREATE INDEX idx_users_covering ON users (points DESC, id, username, city);

-- Пользователи, отсортированных по убыванию очков
SELECT id, username, city, points
FROM users
ORDER BY points DESC;

-- Пользователи, отсортированных по убыванию очков c вычисляемым столбцом
SELECT 
    id,
    username,
    city,
    points,
    ROW_NUMBER() OVER (ORDER BY points DESC) as rank
FROM users
ORDER BY points DESC;