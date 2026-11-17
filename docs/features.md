# Supported SQL

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
