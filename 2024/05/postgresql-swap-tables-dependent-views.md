# PostgreSQL: swap tables with dependent views
May 4, 2024

Sometimes, you need to do some maintenance on a table, and doing a
_table swap_ is a good tool to avoid downtime (e.g. if the maintenance
would lock aggressively and run for a long time). The idea is as
follows:

1. Clone the source table.
1. Perform the maintenance.
1. Make sure they're in sync if needs be.
1. When the maintenance is over, in a transaction, drop the source
   table, and rename the clone to the original name.

It can get a bit more complicated than that if you have foreign keys,
but I won't cover that in this article.

However, another way it gets more complicated is when you have _views_
that depend on the table you want to swap:

```sql
BEGIN;
DROP TABLE example;
ALTER TABLE example_swap RENAME TO example;
```

```
ERROR: cannot drop table example because other objects depend on it
DETAIL: view example_view depends on table example
```

In this case, we need to update `example_view` (and all other views that
depend on `example`) to reference the `example_swap` table before we
perform the actual swap.

If this is a one-off swap, fine, but if you're doing the swap as part of
some automated maintenance task, that won't do it.

## Automatically swapping dependent views

In my case, the dependent views don't change very often (if at all), so
I went with a static list of the views that depend on the table I need
to swap.

Then I use the following script to swap the views:

```sql
CREATE OR REPLACE FUNCTION pg_temp.replace_view_table(view_schema text, view_name text, old_table text, new_table text) RETURNS void AS $$
DECLARE
    view_definition text;
BEGIN
    SELECT definition INTO view_definition
    FROM pg_views
    WHERE schemaname = view_schema
    AND viewname = view_name;

    view_definition := REPLACE(view_definition, old_table, new_table);

    EXECUTE 'CREATE OR REPLACE VIEW ' || view_schema || '.' || view_name || ' AS ' || view_definition;
END;
$$ LANGUAGE plpgsql;
```

This function will redefine the view to point to the new swap table. It
does a basic search and replace in the SQL definition of the view, so
you need to make sure the table name doesn't conflict with anything else
in there.

<div class="note">

**Note:** I'm using `pg_temp` so that the function is local to the
current database connection. I don't want to leave it around permanently
in that case.

</div>

You can now perform the swap as follows:

```sql
BEGIN;
SELECT pg_temp.replace_view_table('public', 'example_view', 'example', 'example_swap');
DROP TABLE example;
ALTER TABLE example_swap RENAME TO example;
COMMIT;
```

The renaming of the table will automatically propagate to the dependent
views, they won't keep referencing the now gone `example_swap` table,
they'll properly point to `example`! 🥳
