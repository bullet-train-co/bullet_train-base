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

## Disabling Saving on Re-order

By default, a call to save the new `sort_order` is triggered automatically on re-order.

### To disable auto-saving

Add the  `data-sortable-save-on-reorder-value="false"` param on the sortable `tbody`:

```html
<tbody data-controller="sortable"
  data-sortable-save-on-reorder-value="false"
  ...
>
```

### To manually fire the save action via a button

Since the button won't be part of the sortable `tbody`, you'll need to wrap both the sortable `tbody` and the save button in a new Stimulus controller in a ancestor element in the DOM.

```js
/* sortable_wrapper_controller.js */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "sortable" ]
  
  saveSortOrder() {
    if (!this.hasSortableTarget) { return }
    this.sortableTarget.dispatchEvent(new CustomEvent("save-sort-order"))
  }
}
```

On the button, add a `data-action`

```html
<button data-action="sortable-wrapper#saveSortOrder">Save Sort Order</button>
```

And on the sortable `tbody`, catch the `save-sort-order` event and define it as the `sortable` target for the `sortable-wrapper` controller:

```html
<tbody data-controller="sortable"
  data-sortable-save-on-reorder-value="false"
  data-action="save-sort-order->sortable#saveSortOrder"
  data-sortable-wrapper-target="sortable"
  ...
>
```

