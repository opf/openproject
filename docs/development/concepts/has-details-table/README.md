---
sidebar_navigation:
  title: Detail tables
description: How to use the HasDetailsTable concern to extend a model with extra columns in a separate table
keywords: development concepts, detail tables, HasDetailsTable, STI, model extension
---

# Detail tables (HasDetailsTable)

The `HasDetailsTable` concern (`app/models/concerns/has_details_table.rb`) gives any ActiveRecord model a companion
"detail" table — a 1:1 side table whose columns are transparently delegated back to the owner. From the outside the
model behaves as if the extra columns lived on its own table.

## Key takeaways

_HasDetailsTable …_

- creates a companion `ApplicationRecord` subclass and registers it as `<Model>Detail` (e.g. `GroupDetail`).
- sets up a `has_one` / `belongs_to` pair with `autosave`, `dependent: :destroy`, and a uniqueness constraint.
- delegates every non-internal column (everything except `id`, timestamps, and the FK) as both readers and writers on the owner.
- delegates `belongs_to` associations declared in the block so you can access them directly on the owner (e.g. `group.parent`).
- auto-builds the detail record on `after_initialize` for new records, so `detail` is never `nil`.
- promotes validation errors from the detail onto the owner so they appear as first-class attributes.
- provides `with_detail` and `where_detail` scopes for eager-loading and filtering.
- duplicates the detail when the owner is `dup`'d.

## When to use

Use `HasDetailsTable` when you want to extend a model with additional columns **without** adding them to the model's
main table. Typical reasons:

- **STI models** that need per-subclass attributes. Adding columns to the shared STI table would leave them `NULL` for every other subclass.
- **Optional feature columns** that only a subset of rows will ever populate.
- **Separation of concerns** — keeping the main table focused on core attributes.

## Why not Rails's DelegatedType?

Rails provides [`delegated_type`](https://api.rubyonrails.org/classes/ActiveRecord/DelegatedType.html) for a similar-sounding
problem: moving type-specific columns out of a shared table. However, it solves a different shape of problem and doesn't
fit the `HasDetailsTable` use case:

- **DelegatedType is polymorphic.** It expects the base model to delegate to one of _several_ possible type classes (e.g. an `Entry` can be a `Message` or a `Comment`). `HasDetailsTable` is a fixed 1:1 extension — every `Group` always has exactly one `GroupDetail`.
- **DelegatedType doesn't delegate columns.** You still access attributes through the delegated object (`entry.entryable.body`). `HasDetailsTable` transparently delegates every column so the detail table is invisible to callers (`group.organizational_unit`).
- **No auto-build, error promotion, or dup support.** `DelegatedType` is intentionally minimal. `HasDetailsTable` handles the boilerplate that would otherwise be needed: auto-building on initialize, promoting validation errors, duplicating the detail on `dup`, and providing query scopes.
- **STI conflicts.** `DelegatedType` stores a type/id pair on the base table. For STI models like `Group` (which already has a `type` column on `users`), introducing a second polymorphic type column would be confusing and semantically wrong — the detail isn't a _different type_ of principal, it's _additional data_ for a specific subclass.

In short: use `DelegatedType` when a base model can delegate to one of many interchangeable types. Use `HasDetailsTable` when a single model needs extra columns in a side table with full transparent access.

## Basic usage

Include the concern and call `has_details_table` in your model:

```ruby
class Widget < ApplicationRecord
  include HasDetailsTable

  has_details_table do
    # Anything here is evaluated inside the generated WidgetDetail class.
    # You can add validations, callbacks, or belongs_to associations.
  end
end
```

This generates a `WidgetDetail` class backed by the `widget_details` table. Every column in that table (except `id`,
`widget_id`, `created_at`, `updated_at`) is delegated to `Widget`, so you can read and write them directly:

```ruby
widget = Widget.new(some_detail_column: "value")
widget.some_detail_column # => "value"
widget.detail             # => #<WidgetDetail ...>
```

## What it sets up automatically

| Feature                | Details                                                                                 |
| ---------------------- | --------------------------------------------------------------------------------------- |
| Detail class           | `<Model>Detail` constant, subclass of `ApplicationRecord`                               |
| Association            | `has_one :<model>_detail` on owner, `belongs_to :<model>` on detail                     |
| Aliases                | `detail` / `detail=` / `build_detail` point to the association                          |
| Column delegation      | Readers delegated via `delegate`, writers via custom methods that auto-build the detail |
| Association delegation | `belongs_to` associations declared in the block are delegated (both object and `_id`)   |
| Auto-build             | `after_initialize` builds the detail for new records                                    |
| Error promotion        | Detail validation errors are copied onto the owner                                      |
| Dup support            | `dup` on the owner also duplicates the detail                                           |
| `with_detail` scope    | `joins` + `includes` for eager loading                                                  |
| `where_detail` scope   | `joins` + `where` for filtering by detail columns                                       |
| Nested attributes      | `accepts_nested_attributes_for` is called automatically                                 |

## Custom foreign key (STI)

When the model uses STI, the FK column won't match the model name. For example, `Group` inherits from `Principal`
(stored in the `users` table), so the FK is `principal_id`, not `group_id`:

```ruby
class Group < Principal
  include HasDetailsTable

  has_details_table(foreign_key: :principal_id) do
    belongs_to :parent, class_name: "Group", optional: true
    validates :parent, presence: true, if: -> { parent_id.present? }
  end
end
```

The corresponding `group_details` table uses `principal_id` as its FK column:

```ruby
create_table :group_details do |t|
  t.references :principal, null: false,
               foreign_key: { to_table: :users },
               index: { unique: true }
  t.boolean :organizational_unit, default: false, null: false
  t.references :parent, foreign_key: { to_table: :users }

  t.timestamps
end
```

## Database table conventions

The detail table must follow these conventions:

| Convention       | Example (`Widget`)                           |
| ---------------- | -------------------------------------------- |
| Table name       | `widget_details`                             |
| FK column        | `widget_id` (or custom, e.g. `principal_id`) |
| Required columns | FK (non-null), `created_at`, `updated_at`    |
| Unique index     | On the FK column (enforces 1:1)              |

The concern reads the detail table's columns at load time to set up delegation, so **the migration must run before the model is loaded**. In practice this means the migration should exist before or alongside the code change — standard Rails migration ordering.

## Adding associations to the detail

Declare `belongs_to` associations inside the block. They are evaluated on the detail class, but delegated to the owner:

```ruby
has_details_table do
  belongs_to :parent, class_name: "Group", optional: true
end
```

This lets you write:

```ruby
group.parent          # delegated to group.detail.parent
group.parent = other  # delegated, auto-builds detail if needed
group.parent_id       # delegated via column delegation
group.parent_id = 42  # delegated via column writer
```

The back-reference from the details table to the owner (`belongs_to :group` / `belongs_to :principal`) is set up automatically — don't declare it yourself.

## Gotchas

- **Migration ordering**: The detail table must exist before the model class loads. If `has_details_table` runs and the table doesn't exist yet, column delegation is deferred to `after_initialize`. This works at runtime but means delegation won't be available at class-load time during `db:migrate`.
- **Writers auto-build**: Custom writer methods call `build_detail` if `detail` is `nil`. This means `assign_attributes` works correctly even before `after_initialize` fires (e.g. in `Model.new(attrs)`).
- **Error promotion**: Validation errors from the detail appear on the owner with the detail's attribute name. If the detail validates `:parent`, the owner will have an error on `:parent`.
- **Uniqueness**: The generated detail class validates uniqueness of the owner association. Combined with the unique DB index this guarantees exactly one detail row per owner.
