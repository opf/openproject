# Configurations

[← User guide](README.md)

Configurations are optional browser, OS or device values used to tag standalone test runs or to
explode a [test plan](plans.md) entry into one run per combination (configuration matrices).

## Where they live

**Project settings → Test management → Configurations.** Permission: **Manage test management**.

Create a **group** (e.g. *Browsers*), then add **values** (e.g. *Chrome*, *Firefox*). Groups and
values are unique by name within the project / group.

Deleting a group deletes its values. Existing runs keep a denormalized `configuration_label` so
history stays readable.

## Optional everywhere

- Standalone runs work with **zero** configurations.
- On **New / Edit run**, pick at most one value per group to tag that run.
- On a **plan entry**, pick many values per group; saving spawns one run per cartesian product.
- If the project has no configurations yet, create-run and plan-entry forms show a hint with a link
  to Project settings → Test management.

## APIv3

- `GET|POST /api/v3/projects/{id}/test_management/configuration_groups`
- `GET|PATCH|DELETE /api/v3/test_management/configuration_groups/{id}`

See [API](api.md).
