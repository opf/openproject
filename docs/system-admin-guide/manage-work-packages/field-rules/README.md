---
sidebar_navigation:
  title: Field rules
  priority: 780
description: Hide, require, lock and pre-fill work package fields per project and type with field rules.
keywords: field rules, required field, read-only, hidden field, default value, work package form
---

# Field rules

Field rules tighten the work package form for a **project and type**. A rule can:

| Setting | Effect |
| --- | --- |
| **Hidden** | The field is not shown and cannot be written. Existing values are kept and still returned by the API. |
| **Required** | The field must be filled when creating a work package (users and API clients). |
| **Read-only** | Users cannot change the field. System updates (for example automatic scheduling) are not blocked. |
| **Enforce on update** | Also require the field when a work package is edited (see below). |
| **Default value** | Pre-fills the field when a work package is created, instead of the native default. |

Rules only **tighten** the native form configuration (*Administration → Work packages → Types → Form configuration*). A rule cannot show a field that the form configuration does not place on the form, cannot make a native or globally required field optional, and never changes stored data.

## Concepts

* **Field rule set** – a named list of rules, for example "Bug rules".
* **Field rule scheme** – assigns a rule set to each work package type, for example Bug → "Bug rules", Story → "Story rules".
* **Project assignment** – a scheme is assigned to a project in *Project settings → Field rule scheme* (requires the *Assign field rule scheme* permission). A project without a scheme behaves natively.

Create rule sets and schemes in *Administration → Work packages → Field rules*. Rule sets and schemes **cannot be deleted**; deactivate them instead (an inactive set or scheme stops applying).

## Configurable fields

Description, assignee, responsible, priority, category, target versions, start date, due date, estimated time and every work package custom field. The subject, type, project, status, author and automatically calculated fields cannot be configured. A custom field must be active in the project to be affected.

## Valid combinations

* A field cannot be **hidden and required**.
* A field that is **required and read-only** needs a default value (otherwise nobody could create a work package).
* A hidden field is also not writable, so *Read-only* is ignored for hidden fields.

## Editing existing work packages

Adding a required rule must not break existing work packages. When editing, a required field is only checked if the field itself is changed or cleared, or the type or project changes. Tick **Enforce on update** to check it on every edit instead.

## Precedence of default values

Value entered by the user → rule default → native default (custom field default, type description template).

## Operations

```shell
bundle exec rake "field_rules:repair[dry_run]"   # report rules of deleted custom fields and impossible states
bundle exec rake "field_rules:repair[apply]"     # remove them
```

Removing the module only drops its five tables (`field_rule_sets`, `field_rules`, `field_rule_schemes`, `field_rule_scheme_items`, `project_field_rule_schemes`). Run `bundle exec rake db:migrate:down VERSION=20261003200000` before removing the gem and delete role permissions named `assign_field_rule_scheme`. Work packages, types and projects are untouched.

## API

See the *Field Rules* section of the API v3 documentation: `/api/v3/field_rule_sets`, `/api/v3/field_rule_schemes`, `PUT /api/v3/projects/{id}/field_rule_scheme` and `GET /api/v3/projects/{id}/types/{type_id}/field_rules`. The work package schema (`/api/v3/work_packages/schemas/...`) reflects the rules (`required`, `writable`, hidden fields omitted).
