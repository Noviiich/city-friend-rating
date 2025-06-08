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