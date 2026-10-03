---
sidebar_navigation:
  title: Type schemes
  priority: 790
description: Limit, order and preselect work package types per project with type schemes.
keywords: type scheme, work package types, default type, project settings
---

# Type schemes

A type scheme limits which work package types can be chosen when a work package is **created** or its type is **changed** in a project. It also defines the order of the types and the default type that is preselected.

Every project always has a type scheme. Projects without an explicit assignment, and all newly created projects, use the **Default Scheme**, whose default type is **Task**. New types are added to the default scheme automatically.

A scheme only references existing types. It never creates types and never changes existing work packages.

## Create a scheme

1. Go to *Administration → Work packages → Type schemes* and click **New type scheme**.
2. Enter a name and an optional description.
3. Tick the types that belong to the scheme, drag the handle to reorder them (or use the arrow buttons / Alt + Up / Down on a row) and choose exactly one **Default** type.
4. Optionally tick **Default scheme for new projects** to make this scheme the default. Exactly one scheme is always the default; making another scheme the default unsets the previous one, and the flag cannot be removed directly.

You can **clone** a scheme (the copy is called "<name> - Custom" and is not assigned to any project) and **deactivate** it (an inactive scheme cannot be newly assigned; its projects move to the default scheme; use **Activate** to enable it again). The default scheme cannot be deactivated. **Type schemes cannot be deleted.**

When you remove a type from a scheme that is used by projects, a confirmation page shows how many projects are affected and how many work packages use the removed type. Existing work packages keep their type.

## Assign a scheme to a project

Users with the *Assign type scheme* permission open *Project settings → Type scheme*, pick a scheme and save (a project cannot be left without a scheme). The page lists the available types in order. A warning is shown for scheme types that are not enabled in the project (*Project settings → Work packages → Types*). If none of the scheme's types is enabled, the project falls back to its enabled types so work package creation is never blocked.

A project without an explicit assignment uses the default scheme.

## What is affected

- New work packages and type changes only offer, and accept, types allowed by the scheme. The default type is preselected.
- Existing work packages keep their type and stay editable, even if their type is not part of the scheme.
- The API v3 form and schema (`type.allowedValues`) reflect the scheme; creating a work package with a type outside the scheme returns a validation error (422).

## Migrate existing instances

The upgrade migration creates the "Default Scheme" from all types (default type Task) and assigns it to every existing project. The rake task repeats this safely, for example after importing data:

```shell
bundle exec rake "type_schemes:migrate[dry_run]"   # print the plan only (default)
bundle exec rake "type_schemes:migrate[manual]"    # make sure the default scheme exists, assign no project
bundle exec rake "type_schemes:migrate[auto]"      # ensure the default scheme and assign it to all projects without a scheme
```

Recommended order: `dry_run`, review the output, then `auto` (or `manual` to assign projects yourself). No work package is changed.

## Removing the module

Run `bundle exec rake db:migrate:down VERSION=20261002100000` before removing the gem, then delete role permissions named `assign_type_scheme`. Removing the module only drops its three tables (`type_schemes`, `type_scheme_items`, `project_type_schemes`). Types, work packages and project type settings are untouched.

## API

See the *Type Schemes* section of the API v3 documentation: `/api/v3/type_schemes`, `PUT /api/v3/projects/{id}/type_scheme` and `GET /api/v3/projects/{id}/available_types`.
