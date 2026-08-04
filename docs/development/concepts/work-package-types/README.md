---
sidebar_navigation:
  title: Types and variants
description: How work package type families work and what to watch out for when writing code that touches types
keywords: work package types, type variants, type families, roots
---

# Work package types and variants

A work package type is either a **root** or a **variant** of a root (identified by the presence of `types.parent_id`). A root together with its variants forms a **family**. Variants let an administrator configure the same type differently per project — a project can use a variant "Mobile Bug" of the root type "Bug" with a different form configuration, workflow or set of project attributes than another one, while everyone still calls it "Bug".

Variants are an administration concept. Everywhere else in the application a family is **one type**. That gap is the source why we need to be careful when interacting with types in every aspect of the application: the type a user picks and the type id a work package stores are not the same thing.

Variants are **currently** behind the `type_variants` feature flag.

## Key takeaways

- A project runs **exactly one member** of each family. `Projects::Types::AddService` enforces it; `Projects::Types::SwitchVariantService` moves a project from one member to another.
- A work package stores the member **its project runs**. In a project running the variant, a "Bug" work package has the variant's `type_id`.
- Users pick roots. `/api/v3/types` returns roots only, the global create form offers roots only, and every screen shows the root's name.
- Therefore: any code comparing a type id against `work_packages.type_id`, listing types for users, or reading a type's name, colour or flags off its own column has to go through the family.
- `Type` owns the family SQL. Use it rather than writing `parent_id || id` again.

## What a variant inherits

`Type#inherited_core_setting` reads these through to the root, so a variant's own columns are ignored: `name`, `color_id`, `is_milestone`, `is_in_roadmap`.

Its own: `is_default` (at most one member per family may carry it — `WorkPackageTypes::MakeDefaultService`), `position`, and every configuration aspect it does not link to its root. Aspects are listed in `Type::ConfigurationLink::ASPECTS`: `pdf_export`, `defaults`, `workflows`, `form_configuration`, `project_attributes`. A new variant starts out linked to its parent for all of them, and resolution happens in SQL — see `Type::ConfigurationLinkable`, which is also where the performance notes for that machinery live.

## Names

| Method | Returns | Use for |
|--------|---------|---------|
| `#name` | the root's name | everything users see |
| `#own_name` | the variant's own label | nothing user-facing |
| `#composite_name` | `"Bug: Mobile Bug"` | administration screens where members must be told apart |

`#name` is an override, **not** a column. `pluck(:name)`, `select(:name)` and `order(:name)` all bypass it and leak the variant's own label.

## The API to use

All of these live on `Type`:

| You need | Use |
|----------|-----|
| every member of the families given types belong to | `Type.in_families_of(types)`, `Type.family_ids(types)` |
| the roots of those families | `Type.roots_of(types)`, `Type.root_ids(types)`, `type.root_id` |
| the root id in SQL, with a `types` row joined | `Type.root_id_expression("types")` |
| the root id in SQL, from a bare `type_id` column | `Type.root_id_subquery("work_packages.type_id")` |
| to compare two joined `types` rows | `Type.same_family_condition("left", "right")` |
| a setting as the family has it (`position`, `is_milestone`, …) | `Type.family_setting_expression(:position, "types")` |
| whether a project offers this type | `type.enabled_in?(project)` |
| the milestone types | `Type.milestone` |

`in_families_of` and `roots_of` are scopes and accept ids, records or a relation. They resolve in a single query, so they are safe to use as subqueries.

## Gotchas

### Comparing type ids to work packages

A list of type ids from settings, a filter or a form will hold whatever the user picked — usually a root. The work packages hold the member their project runs.

```ruby
# Wrong: misses every work package in a project running a variant
where(type_id: selected_type_ids)

# Right
where(type_id: Type.family_ids(selected_type_ids))
```

In raw SQL, resolve both sides to their root:

```sql
-- see WorkPackages::Scopes::WithoutExcludedType for the full query
#{Type.root_id_expression('excluded_types')} = #{Type.root_id_subquery('work_packages.type_id')}
```

Prefer `root_id_subquery` over joining `types` yourself: the query may already have `types` joined by an eager load, and a second join collides.

### Reading names and flags from columns

```ruby
types.pluck(:id, :name)               # leaks the variant's own label
where(types: { is_milestone: true })  # reads the variant's meaningless column
Type.order(:name)                     # orders by the wrong string

types.map { |type| [type.id, type.name] }  # reads the override
merge(Type.milestone)                      # resolves the flag through the family
```

If a flag needs resolving in SQL that `Type.milestone` does not cover, build the condition with `Type.family_setting_expression`.

### Grouping and sorting

Group by the root id, not the stored id, or one family produces several groups with identical captions. Sort by the root's position: a variant's `position` is append order within its family and no display order at all (`Type#sorted_variants`). Both are configured on the `type` select in `Queries::WorkPackages::Selects::PropertySelect`.

### Filters: offer roots, accept the family

A list filter validates its values against `allowed_values` (`Queries::Filters::Strategies::List`). Restricting that to roots invalidates every filter built inside a project, because a project's filter names the member that project runs. So:

- keep `allowed_values` permissive over the family — it is what validation uses;
- offer roots where users choose (`autocomplete_options`, the APIv3 `allowedValues` href);
- expand to the family in `#where`.

`Queries::Projects::Filters::TypeFilter` and `Queries::WorkPackages::Filter::TypeFilter` both follow that split.

### Preload the parent — with `preload`, not `includes`

Reading `#name` or `#color` over a collection of types loads each variant's parent, so preload it:

```ruby
scope.preload(:color, parent: :color)
```

Use `preload` rather than `includes`. `includes` becomes an eager load as soon as a caller `pluck`s off the scope, which self-joins `types` — and then an unqualified `ORDER BY position` is ambiguous between the two. That is exactly how a change to `WorkPackages::BaseContract#assignable_types` broke the BCF project extensions endpoint, and an aborted transaction took two dozen unrelated specs with it.

For the same reason, `Type`'s `default_scope` orders by `types.position`, qualified. Leave it that way.

### Setting a type on a work package

Setting the root is fine and normal — `WorkPackages::SetAttributesService#resolve_type_within_family` swaps in whichever member the work package's project runs, on create and when moving between projects. So:

- do not validate exact membership of `project.types`; ask `type.enabled_in?(project)`;
- do not warn users that a type is unavailable in a target project before checking by family (`WorkPackages::Moves::FormComponent`).

### Administration screens

Anywhere an administrator configures a single member — workflows, form configuration, the configuration source pickers — use `#composite_name`, otherwise the screen shows several rows called "Bug".

### The frontend

`/api/v3/types` returns roots. `/api/v3/projects/:id/types` returns the members that project runs, titled with the root's name. A work package's `_links.type` points at the member it stores.

Two type hrefs from one family therefore never compare equal, and the frontend cannot tell they are related. Where the frontend needs to match, hand it the family from the backend rather than a single href — `API::V3::Queries::Columns::QueryRelationToTypeColumnRepresenter` exposes `_links.types` for that, and keys its cache on the whole family so a new variant is picked up.

## Testing

Enable the flag and set up the shape that breaks things: a family whose variant is what a project actually runs.

```ruby
context "when the project runs a variant", with_flag: { type_variants: true } do
  shared_let(:root_type) { create(:type, name: "Bug") }
  shared_let(:variant) { create(:type, name: "Mobile Bug", parent: root_type) }
  shared_let(:project) { create(:project, types: [variant]) }
  shared_let(:work_package) { create(:work_package, project:, type: variant) }

  it "behaves as it does for a root" do
    # ...
  end
end
```

Note that the factory bypasses `Projects::Types::AddService`, so it will happily give a project two members of one family — a state the application prevents. Assign one member per family.

The question to ask of any change touching types: **does this still hold when the project runs the variant instead of the root?** If the code compares ids, lists types, reads a name or a flag, or renders a group, the answer is usually no until it goes through the family.

## Known limitations

Grouping a cost report by type still groups per family member, so a cross-project report can show two rows named "Bug". `Report::GroupBy` prefixes group fields with a table name, so the root id expression cannot be injected without rewriting its aggregation layer. The numbers per row are correct.
