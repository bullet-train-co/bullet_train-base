# Super Scaffolding with the `--sortable` option

When issuing a `bin/super-scaffold crud` command, you can pass the `--sortable` option like this:

```
# E.g. Pages belong to a Site and are sortable via drag-and-drop:
rails g model Page site:references name:string path:text
bin/super-scaffold crud Page Site,Team name:text path:text --sortable
```

The `--sortable` option:

1. wraps the table's body in a `sortable` Stimulus controller, providing drag and drop re-ordering
2. adds a `reorder` action to your resource via `include SortableActions`, triggered automatically on re-order
3. adds a migration to add the `sort_order` column to your model to store the ordering
4. adds a `default_scope` and auto increments `sort_order` on create via `include Sortable` on the model