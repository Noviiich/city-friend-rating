-- (13s)
DO $$
DECLARE
    batch_size INTEGER := 50000;
    total_records INTEGER := 10000000;
    current_batch INTEGER := 0;
    cities TEXT[] := ARRAY['Москва', 'Орел', 'Калуга', 'Брянск', 'Мценск', 'Тула', 'Волгоград', 'Пенза', 'Калининград', 'Хабаровск'];
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    start_time := clock_timestamp();
    
    WHILE current_batch * batch_size < total_records LOOP
        INSERT INTO users (username, city, points)
        SELECT 
            'user' || (current_batch * batch_size + generate_series),
            cities[1 + (random() * (array_length(cities, 1) - 1))],
            (random() * 1000000)
        FROM generate_series(1, batch_size);
        
        current_batch := current_batch + 1;
        
        -- Вывод прогресса каждые 10 батчей
        IF current_batch % 10 = 0 THEN
            end_time := clock_timestamp();
            RAISE NOTICE 'Обработано % батчей из %. Вставлено % записей. Время: %', 
                current_batch, 
                (total_records / batch_size)::INTEGER,
                current_batch * batch_size,
                end_time - start_time;
            COMMIT;
        END IF;
    END LOOP;
    
    end_time := clock_timestamp();
    RAISE NOTICE 'Генерация завершена! Всего записей: %. Общее время: %', total_records, end_time - start_time;
END $$;