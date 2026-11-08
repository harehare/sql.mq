<h1 align="center">sql.mq</h1>

A SQL DDL parser implemented as an [mq](https://github.com/harehare/mq) module. It reads table definitions and renders them as Markdown tables.

## Features

- `sql_ast`: parses SQL into an AST.
  - Queries: CTEs (`RECURSIVE`), joins (including `LATERAL`, `CROSS/OUTER APPLY`, `STRAIGHT_JOIN`), subqueries, window functions and `WINDOW` clauses, set operations, `FETCH FIRST`, `TOP`, `FOR UPDATE` / `LOCK IN SHARE MODE`, `GROUP BY ... WITH ROLLUP`, `TABLESAMPLE`, table hints
  - Expressions: arrays and subscripts, `ANY/ALL/SOME`, `COLLATE`, `AT TIME ZONE`, aggregate `ORDER BY`, `WITHIN GROUP`, `E'..'` / `N'..'` / `X'..'` / `B'..'` / `$tag$..$tag$` literals, JSON and regex operators
  - DML: `INSERT` (`ON CONFLICT`, `ON DUPLICATE KEY UPDATE`, `SET`), `UPDATE` (tuple assignment, `ORDER BY` / `LIMIT`), `DELETE`, and `WITH` in front of any of them
  - DDL: `CREATE TABLE/INDEX/VIEW`, `ALTER TABLE`, `DROP`, `TRUNCATE`, `COMMENT ON`
- `sql_stringify`: prints an AST back to SQL, adding parentheses where precedence needs them
- `sql_find`: collects nodes of a type from anywhere in an AST (e.g. every referenced `table`)
- `sql_parse` / `sql_to_markdown`: table definitions from DDL, rendered as Markdown tables
- Quoted identifiers (`"x"`, `` `x` ``, `[x]`), `$1` / `?` / `:name` parameters, `--` and `/* */` comments
- Statements that are not understood (`GRANT`, `SET`, ...) become `{"type": "unknown", "sql": ...}` instead of failing

## Installation

Copy `sql.mq` to your mq module directory, or place it anywhere and reference it with `-L`.

### HTTP Import (no local installation needed)

```sh
mq --allow-http-import -I raw 'import "github.com/harehare/sql.mq" | sql::sql_to_markdown(.)' schema.sql
```

## Usage

```sh
mq -L . -I raw 'import "sql" | sql::sql_to_markdown(.)' schema.sql
mq -L . -I raw 'include "sql" | sql_ast(.) | sql_find(., "table") | map(., fn(t): t["name"];)' query.sql
```

## API

### `sql_ast(input)`

Returns an array with one node per statement. Every node is a dict with a `"type"` field. Raises an error with the offending token and offset on a syntax error.

| Statement | `type` | Main fields |
|---|---|---|
| query | `select`, `set_op`, `values` | `with`, `distinct`, `columns`, `from`, `where`, `group_by`, `having`, `windows`, `order_by`, `limit`, `offset`, `fetch`, `locking` |
| `INSERT` | `insert` | `table`, `columns`, `source`, `on_conflict`, `on_duplicate_key_update`, `returning` |
| `UPDATE` / `DELETE` | `update`, `delete` | `table`, `alias`, `set`, `from` / `using`, `where`, `returning` |
| `CREATE TABLE` | `create_table` | `name`, `columns` (`column_def`), `constraints` (`constraint`), `comment`, `options`, `partition_by` |
| other DDL | `create_index`, `create_view`, `alter_table`, `drop`, `truncate`, `comment_on` | |
| anything else | `unknown` | `keyword`, `sql` |

`column_def` keeps `generated` (expression and `STORED`/`VIRTUAL`), `identity`, `auto_increment_style` and `on_update`. Flags such as `only`, `inner`, `outer`, `select_all`, `offset_rows` and `fetch.next` record how the SQL was spelled.

Expressions: `literal`, `ident`, `star`, `param`, `unary`, `binary`, `is`, `between`, `in`, `call`, `case`, `cast`, `exists`, `subquery`, `tuple`, `typed_literal`.
Table references: `table`, `subquery`, `table_function`, `join`.

Names are kept as written (case preserved, quotes removed). Table names are dotted strings such as `"public.users"`.

Quoting is kept in a sibling field named `<field>_quoted` so that printing gives the same SQL back:

| Name field | Flags |
|---|---|
| single name (`alias`, `column_def.name`, ...) | `false` for a bare word, otherwise the quote character: `"`, `` ` `` or `[` |
| list of names (`columns`, `using`, `include`, ...) and parts of a dotted name (`ident.parts`, `table.name`, ...) | an array of the same values, one per name or part |
| list of dotted names (`drop.names`, `truncate.tables`) | an array of arrays |

```sh
mq -I raw 'include "sql" | sql_ast(.)[0]["from"][0]["name_quoted"]' <<< 'SELECT * FROM `db`.`Users`'
# => ["`", "`"]
```

### `sql_stringify(node)`

Prints a node as SQL. An array of statements is printed one per line, each ending with `;`.

### `sql_find(node, type)`

Returns every node of the given `type` found anywhere inside `node`.

### `sql_parse(input)`

Returns an array of tables built from `CREATE TABLE`, `ALTER TABLE ... ADD CONSTRAINT` and `COMMENT ON`. Other statements are skipped.

```
{
  "name": "public.users",
  "comment": "Registered users",
  "columns": [{
    "name", "type", "nullable", "default", "primary_key", "unique",
    "auto_increment", "references", "comment"
  }],
  "primary_key": ["id"],
  "foreign_keys": [{"columns": [...], "ref_table": "...", "ref_columns": [...]}],
  "unique": [["email"]]
}
```

### `sql_to_markdown(input)` / `sql_table_to_markdown(table)`

Renders tables from `sql_parse` as Markdown sections.

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

## Limitations

- Backslash escapes in plain string literals and slices with identifier bounds (`a[i:j]`) are not handled.
- Multi-table `UPDATE` / `DELETE` (`UPDATE t JOIN u ...`, `DELETE t FROM ...`), `ORDER BY ... USING`, `ROWS FROM` and `DROP ... CASCADE CONSTRAINTS` raise a syntax error.
- `MERGE`, `CREATE FUNCTION/TRIGGER/TYPE/...`, `EXPLAIN` and other statements become `unknown` nodes: their text is kept but not parsed.
- Table options other than `COMMENT` are kept as `name`/`value` pairs, `PARTITION BY` as raw text. `IDENTITY(1,1)` arguments and identity sequence options are not parsed.
- Keywords are printed in upper case and some spellings are normalized (`TEMP` as `TEMPORARY`, `USING btree` as `USING BTREE`).
- Quote style is not recorded for function names, window names and `FOR UPDATE OF` tables.

## Compatibility

Requires [mq](https://github.com/harehare/mq) v0.10 or later.

## License

MIT
