ALTER TABLE users ALTER COLUMN username SET NOT NULL;
ALTER TABLE users ALTER COLUMN city SET NOT NULL;
ALTER TABLE users ALTER COLUMN points SET NOT NULL;
ALTER TABLE users ADD PRIMARY KEY (id);
ALTER TABLE users ADD CONSTRAINT users_username_unique UNIQUE (username);