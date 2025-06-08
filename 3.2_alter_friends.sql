ALTER TABLE friends ALTER COLUMN user_id SET NOT NULL; --4s
ALTER TABLE friends ALTER COLUMN friend_id SET NOT NULL; --5s
ALTER TABLE friends ADD PRIMARY KEY (id); 30s
ALTER TABLE friends ADD CONSTRAINT fk_friends_user_id --30s
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE friends ADD CONSTRAINT fk_friends_friend_id --50s
    FOREIGN KEY (friend_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE friends ADD CONSTRAINT unique_user_friend --45s
    UNIQUE(user_id, friend_id);
