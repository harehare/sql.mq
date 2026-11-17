# Limitations

- Backslash escapes in plain string literals and slices with identifier bounds (`a[i:j]`) are not handled.
- Multi-table `UPDATE` / `DELETE` (`UPDATE t JOIN u ...`, `DELETE t FROM ...`), `ORDER BY ... USING`, `ROWS FROM` and `DROP ... CASCADE CONSTRAINTS` raise a syntax error.
- `MERGE`, `CREATE FUNCTION/TRIGGER/TYPE/...`, `EXPLAIN` and other statements become `unknown` nodes: their text is kept but not parsed.
- Table options other than `COMMENT` are kept as `name`/`value` pairs, `PARTITION BY` as raw text. `IDENTITY(1,1)` arguments and identity sequence options are not parsed.
- Keywords are printed in upper case and some spellings are normalized (`TEMP` as `TEMPORARY`, `USING btree` as `USING BTREE`).
- Quote style is not recorded for function names, window names and `FOR UPDATE OF` tables.
