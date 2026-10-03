---
sidebar_navigation:
  title: Type schemes
  priority: 790
description: Limit, order and preselect work package types per project with type schemes.
keywords: type scheme, work package types, default type, project settings
---

# Type schemes

A type scheme limits which work package types can be chosen when a work package is **created** or its type is **changed** in a project. It also defines the order of the types and the default type that is preselected.

A scheme only references existing types. It never creates types and never changes existing work packages.

## Create a scheme

1. Go to *Administration → Work packages → Type schemes* and click **New type scheme**.
2. Enter a name and an optional description.
3. Tick the types that belong to the scheme, set their position and choose exactly one **Default** type.
4. Optionally tick **Default scheme for new projects**. Only one scheme can be the default; it is assigned automatically to every newly created project.

You can **clone** a scheme (the copy is called "<name> - Custom" and is not assigned to any project), **deactivate** it (an inactive scheme no longer filters types, cannot be newly assigned and loses its "default for new projects" flag; use **Activate** to enable it again) or **delete** it. A scheme that is still assigned to projects cannot be deleted; the error lists the projects.

When you remove a type from a scheme that is used by projects, a confirmation page shows how many projects are affected and how many work packages use the removed type. Existing work packages keep their type.

## Assign a scheme to a project

Users with the *Assign type scheme* permission open *Project settings → Type scheme*, pick a scheme and save. The page lists the available types in order. A warning is shown for scheme types that are not enabled in the project (*Project settings → Work packages → Types*). If none of the scheme's types is enabled, the project falls back to its enabled types so work package creation is never blocked.

A project without a scheme behaves as before: all enabled types are available.

## What is affected

- New work packages and type changes only offer, and accept, types allowed by the scheme. The default type is preselected.
- Existing work packages keep their type and stay editable, even if their type is not part of the scheme.
- The API v3 form and schema (`type.allowedValues`) reflect the scheme; creating a work package with a type outside the scheme returns a validation error (422).

## Migrate existing instances

Run the rake task to create a "Default Scheme" from the types currently enabled in at least one project:

```shell
bundle exec rake "type_schemes:migrate[dry_run]"   # print the plan only (default)
bundle exec rake "type_schemes:migrate[manual]"    # create the scheme, assign no project
bundle exec rake "type_schemes:migrate[auto]"      # create the scheme and assign all projects without a scheme
```

Recommended order: `dry_run`, review the output, then `auto` (or `manual` to assign projects yourself). No work package is changed.

## Removing the module

Run `bundle exec rake db:migrate:down VERSION=20261002100000` before removing the gem, then delete role permissions named `assign_type_scheme`. Removing the module only drops its three tables (`type_schemes`, `type_scheme_items`, `project_type_schemes`). Types, work packages and project type settings are untouched.

## API

See the *Type Schemes* section of the API v3 documentation: `/api/v3/type_schemes`, `PUT /api/v3/projects/{id}/type_scheme` and `GET /api/v3/projects/{id}/available_types`.
