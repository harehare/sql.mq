-- Blog schema
CREATE TABLE IF NOT EXISTS public.users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'User id',
  email VARCHAR(255) NOT NULL UNIQUE,
  name TEXT DEFAULT 'anonymous',
  balance DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now()
) COMMENT='Registered users';

CREATE TABLE posts (
  id integer NOT NULL,
  user_id integer NOT NULL REFERENCES public.users (id) ON DELETE CASCADE,
  slug varchar(64),
  body text, /* inline | pipe */
  status text DEFAULT 'draft'::text,
  CONSTRAINT posts_pkey PRIMARY KEY (id),
  UNIQUE (slug),
  KEY idx_user (user_id)
);

CREATE TABLE tags (id int, label text);
ALTER TABLE ONLY tags ADD CONSTRAINT tags_pkey PRIMARY KEY (id);
COMMENT ON TABLE posts IS 'Blog posts';
COMMENT ON COLUMN posts.slug IS 'URL slug | unique';
