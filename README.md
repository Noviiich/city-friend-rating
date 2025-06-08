# Тестовое задание в команию Mish
Представляет собой высокопроизводительную систему рейтинга пользователей с городами и друзьями

## Основные оптимизации

### 1. Создание таблиц

При создании таблиц удалил все ограничения, для того, чтобы вставка больших данных(10М+ записей) расходовала меньше времени

```sql
CREATE TABLE users (
    id BIGSERIAL,
    username VARCHAR(50),
    city VARCHAR(50),
    points INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE friends (
    id BIGSERIAL,
    user_id BIGINT,
    friend_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2. Батчевые вставки

В данных в таблицы ```users``` и ```friends``` произвожу небольшим объемом данных(батчами) для того, чтобы ибежать переполнения памяти при обработке больших объёмов данных и также снизить риск сбоя длительной транзакции 

```sql
INSERT INTO users (username, city, points)
SELECT 
    'user' || (current_batch * batch_size + generate_series),
    cities[1 + (random() * (array_length(cities, 1) - 1))],
    (random() * 1000000)
FROM generate_series(1, batch_size);
```

```sql
INSERT INTO friends (user_id, friend_id)
SELECT DISTINCT
    user_id,
    friend_id
FROM (
    SELECT 
        user_id,
        (random() * 9999999)::bigint + 1 as friend_id,
        generate_series(1, (random() * 19)::int + 1)
    FROM generate_series(start_user, end_user) as user_id
)
WHERE friend_id != user_id;
```

### 3. Генерация данных на лету

С помощью ```generate_series()``` созданиются диапазонов ID и случайных значений для ускорения вставки множества строк, чтобы эффективно распределять ресурсы БД

```sql
generate_series(start_user, end_user)
```

### 4. Вставка ограничений в таблицы

После заполнения таблиц исходными данными, причем они генерируются таким образом, чтобы избежать конфликтов, производится добавление ограничений в таблицы. Это дает нам огромное преимущество по сравнению с тем, чтобы эти ограничения изначально были в таблице, таким образом, время, за которое данные вставляются в таблицу(особеено актуально для таблицы friends) дало x10-15 по времени вставки с учетом времени вставки самих ограничений.

### Для таблицы users
```sql
ALTER TABLE users ALTER COLUMN username SET NOT NULL;
ALTER TABLE users ALTER COLUMN city SET NOT NULL;
ALTER TABLE users ALTER COLUMN points SET NOT NULL;
ALTER TABLE users ADD PRIMARY KEY (id);
ALTER TABLE users ADD CONSTRAINT users_username_unique UNIQUE (username);
```
### Для таблицы friends
```sql
ALTER TABLE friends ALTER COLUMN user_id SET NOT NULL; 
ALTER TABLE friends ALTER COLUMN friend_id SET NOT NULL; 
ALTER TABLE friends ADD PRIMARY KEY (id); 30s
ALTER TABLE friends ADD CONSTRAINT fk_friends_user_id 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE friends ADD CONSTRAINT fk_friends_friend_id
    FOREIGN KEY (friend_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE friends ADD CONSTRAINT unique_user_friend 
    UNIQUE(user_id, friend_id);
```


# Решение задач
Добавил индекс для поиска пользователей. Индекс содержит все данные, необходимые для выполнения запроса (включая id, username, city), что исключает дополнительное обращение к таблице

```sql
CREATE INDEX idx_users_covering ON users (points DESC, id, username, city);
```

## Пользователи, отсортированных по убыванию очков
```sql
-- уменьшение времени с 6s до 3s
SELECT id, username, city, points
FROM users
ORDER BY points DESC;
```

## Пользователи, отсортированных по убыванию очков c вычисляемым столбцом
```sql
-- уменьшение времени с 10s до 5s
SELECT 
    id,
    username,
    city,
    points,
    ROW_NUMBER() OVER (ORDER BY points DESC) as rank
FROM users
ORDER BY points DESC;
```

## Вывести имя пользователя, кол-во очков, место пользователя в общем рейтинге, в рейтинге по его городу и среди его друзей

Использовал ```CTE``` чтобы один раз получить данные о пользователе и избежать повторных обращений к таблице users
```sql
WITH target_user AS (
    SELECT id, city, points
    FROM users
    WHERE username = 'user123' -- Замените на нужного пользователя
)
```

Для расчета рейтинга использую подзапрос с ```COUNT(*)```, вместо ```SELECT ``` с сортировкой ```DESC```
```sql
(SELECT COUNT(*) FROM users u2 WHERE u2.points > tu.points)
```

Использую ```UNION ALL``` вместо ```UNION``` чтобы избежать лишней проверки на дубликаты
```sql
(SELECT COUNT(*) + 1 FROM (
    SELECT u.points
    FROM friends f
    JOIN users u ON f.friend_id = u.id
    WHERE f.user_id = tu.id
    UNION ALL
    SELECT points FROM target_user
) fd WHERE fd.points > tu.points)
```

### Полный пример
```sql
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
```

## Топ N пользователей по общему рейтингу
```sql
SELECT id, username, points
FROM users
ORDER BY points DESC
LIMIT 100; -- N
```

## Топ N пользователей в указанном городе
```sql
SELECT id, username, points
FROM users
WHERE city = 'Москва' -- Подставить нужный город
ORDER BY points DESC
LIMIT 100; -- N
```

## Топ N друзей указанного пользователя
```sql
WITH target_user AS (
    SELECT id
    FROM users
    WHERE username = 'user1234' -- Имя пользователя
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
LIMIT 100; -- N
```