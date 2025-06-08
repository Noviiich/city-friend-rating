--(3 min)
DO $$
DECLARE
    batch_size INTEGER := 100000;
    total_users INTEGER := 10000000;
    current_batch INTEGER := 0;
    start_user INTEGER;
    end_user INTEGER;
BEGIN
    WHILE current_batch * batch_size < total_users LOOP
        start_user := current_batch * batch_size + 1;
        end_user := LEAST((current_batch + 1) * batch_size, total_users);
        
        RAISE NOTICE 'Обработка пользователей с % по %', start_user, end_user;
        
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
        
        current_batch := current_batch + 1;

        COMMIT;
    END LOOP;
END $$;