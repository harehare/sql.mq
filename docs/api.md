# API Reference

## `sql_ast(input)`

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
mq -L . -I raw 'import "sql" | sql::sql_ast(.)[0]["from"][0]["name_quoted"]' <<< 'SELECT * FROM `db`.`Users`'
# => ["`", "`"]
```

## `sql_stringify(node)`

Prints a node as SQL. An array of statements is printed one per line, each ending with `;`.

## `sql_find(node, type)`

Returns every node of the given `type` found anywhere inside `node`.

## `sql_parse(input)`

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

## `sql_to_markdown(input)` / `sql_table_to_markdown(table)`

Renders tables from `sql_parse` as Markdown sections.
