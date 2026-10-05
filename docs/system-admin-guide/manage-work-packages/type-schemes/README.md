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

A scheme references existing types and can also create new ones. It never changes existing work packages.

## Create a scheme

1. Go to *Administration → Work packages → Type schemes* and click **New type scheme**.
2. Enter a name and an optional description.
3. Tick the types that belong to the scheme and choose exactly one **Default** type. If you untick the default type, the first remaining ticked type becomes the default.

   To add a type that does not exist yet, enter one name per line (or separated by commas) in **Add new types**. Each new name creates a work package type available in the whole instance and adds it to the scheme. A name matching an existing type is matched regardless of case and is reused without creating a duplicate. Newly created types are also added to the default scheme automatically.

   Each type has its own **Color**. Choose one from the list (a swatch previews the selection) or choose **Custom color** and use the color picker; a custom color is stored as a regular color and reused when the same value is picked again. Colors are stored per scheme, so the same type can look different in another scheme. Types created from **Add new types** start without a color; set it in the Color column once the row appears.
4. Reorder the types: drag the handle with the mouse, or use the up and down arrow buttons in each row (they work with keyboard, touch and screen readers). With the keyboard you can also press Alt + Up arrow or Alt + Down arrow while focus is inside a row. Each move is announced to screen readers and keyboard focus stays on the control you used. The *Position* number of every row is updated automatically and can still be edited by hand, for example when JavaScript is disabled.
5. Optionally tick **Default scheme for new projects** to make this scheme the default. Exactly one scheme is always the default; making another scheme the default unsets the previous one, and the flag cannot be removed directly.

You can **clone** a scheme (the copy is called "<name> - Custom" and is not assigned to any project) and **deactivate** it (an inactive scheme cannot be newly assigned; its projects move to the default scheme; use **Activate** to enable it again). Deactivating asks for confirmation and tells you how many projects will switch to the default scheme. The default scheme is marked with a **Default** label in the list. The default scheme cannot be deactivated. **Type schemes cannot be deleted.**

When you save changes to a scheme that is used by at least one project, a confirmation page shows how many projects are affected. If you removed types, it also lists how many work packages use each removed type. Existing work packages keep their type.

## Assign a scheme to a project

Users with the *Assign type scheme* permission open *Project settings → Type scheme*, pick a scheme and save (a project cannot be left without a scheme). The page lists the available types in order and marks the default type. A warning is shown for scheme types that are not enabled in the project (*Project settings → Work packages → Types*). If none of the scheme's types is enabled, the project falls back to its enabled types so work package creation is never blocked.

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

## Operations: backup, repair and rollback

Back up the database before upgrading. The module only adds the tables `type_schemes`, `type_scheme_items` and `project_type_schemes`; it never changes `types`, `work_packages` or `project_types`.

The system always keeps exactly one active **Default Scheme**, every active scheme has exactly one default type and every project resolves to a scheme. Deleting a type removes it from all schemes (database cascade) and can leave a scheme without a default type, and data imports or direct SQL can leave projects without an assignment. Work package creation is never blocked in these cases: it falls back to the project's enabled types. Restore the invariants with:

```shell
bundle exec rake "type_schemes:repair[dry_run]"   # list what would be changed (default)
bundle exec rake "type_schemes:repair[apply]"     # write the changes
```

The repair re-activates or recreates the Default Scheme, adds missing types to it, promotes a default type (Task if available) in schemes that lost theirs, and assigns the Default Scheme to projects without a usable scheme. It is idempotent, takes an advisory lock and can be run at any time. Schemes that are active but have no types at all are only reported; edit them in the administration.

Running the upgrade migrations twice is safe: the seed migration only creates the Default Scheme if it does not exist and only assigns projects without a scheme.

## Removing the module

Roll back both migrations in this order before removing the gem, then delete role permissions named `assign_type_scheme`:

```shell
bundle exec rake db:migrate:down VERSION=20261003100000
bundle exec rake db:migrate:down VERSION=20261002100000
```

Removing the module only drops its three tables. Types, work packages and project type settings are untouched. All scheme data is lost on rollback; restore from the backup if you want to reinstall the module with the same schemes. Reinstalling creates a fresh Default Scheme from all types.

## API

See the *Type Schemes* section of the API v3 documentation: `/api/v3/type_schemes`, `PUT /api/v3/projects/{id}/type_scheme` and `GET /api/v3/projects/{id}/available_types`.
