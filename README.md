<h1 align="center">sql.mq</h1>

A SQL parser implemented as an [mq](https://github.com/harehare/mq) module. It parses SQL into an AST, prints it back, and renders `CREATE TABLE` definitions as Markdown tables.

## Features

- `sql_ast`: SQL → AST (queries, DML, DDL; unsupported statements become `unknown` nodes)
- `sql_stringify`: AST → SQL
- `sql_find`: collect nodes of a given type (e.g. every referenced `table`)
- `sql_parse` / `sql_to_markdown`: DDL → table definitions → Markdown

## Installation

Copy `sql.mq` to your mq module directory, or place it anywhere and reference it with `-L`. Requires [mq](https://github.com/harehare/mq) v0.10 or later.

Without installing:

```sh
mq --allow-http-import -I raw 'import "github.com/harehare/sql.mq" | sql::sql_to_markdown(.)' schema.sql
```

## Usage

```sh
# DDL to Markdown
mq -L . -I raw 'import "sql" | sql::sql_to_markdown(.)' schema.sql

# List referenced tables
mq -L . -I raw 'import "sql" | sql::sql_ast(.) | sql::sql_find(., "table") | map(., fn(t): t["name"];)' query.sql
```

The module must be loaded with `import "sql"`; `include "sql"` is not supported.

## Example

Given `schema.sql`:

```sql
CREATE TABLE users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'User id',
  email VARCHAR(255) NOT NULL UNIQUE,
  name TEXT DEFAULT 'anonymous'
) COMMENT='Registered users';

CREATE TABLE posts (
  id INT NOT NULL,
  user_id INT NOT NULL REFERENCES users (id),
  PRIMARY KEY (id)
);
```

```sh
mq -L . -I raw 'import "sql" | sql::sql_to_markdown(.)' schema.sql
```

````markdown
## users

Registered users

| Column | Type | Null | Default | Key | Comment |
|---|---|---|---|---|---|
| `id` | `BIGINT` | NO |  | PK | User id |
| `email` | `VARCHAR(255)` | NO |  | UK |  |
| `name` | `TEXT` | YES | `'anonymous'` |  |  |

## posts

| Column | Type | Null | Default | Key | Comment |
|---|---|---|---|---|---|
| `id` | `INT` | NO |  | PK |  |
| `user_id` | `INT` | NO |  | FK: users.id |  |
````

## Documentation

- [API reference](docs/api.md): functions, AST node types, quoting flags
- [Supported SQL](docs/features.md)
- [Limitations](docs/limitations.md)

## License

MIT
