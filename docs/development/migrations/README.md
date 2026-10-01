# Migrations

## Overview

OpenProject follows the Rails approach for database migrations, which allows for evolving the database schema over time and also allows for rolling back migrations. However, OpenProject implements an additional migration squashing mechanism to manage database changes across major versions.

This is done so that old migrations don't have to be maintained. Oftentimes, migrations contain data changes along with structural changes. For those data changes, where existing data needs to be moved from one structure to another, additional libraries are necessary or application code is referenced. Both the external libraries as well as the application code might change, leading to hard to spot and costly to fix bugs. 

## Migration versioning

For every major version of OpenProject, migrations are squashed. This means that an installation will have to be migrated to the latest major version before it can be migrated to the current one. For example, to migrate to OpenProject 16.x, an OpenProject 15.x installation must be present first.
Not all migrations are squashed. Migrations added within the last major version are left unchanged. They will be squashed later.

## How migration squashing works

The squashing process consolidates multiple migrations into single aggregated migration files. For example, `db/migrate/1000015_aggregated_migrations.rb` contains squashed migrations for the core application, while modules have their own aggregated migration files (e.g., `modules/documents/db/migrate/1012015_aggregated_documents_migrations.rb`). The files' objective is to create the same database schema that the migrations they squash would have created.

### Technical implementation

The squashing mechanism is implemented through several parts:

- **File per module with version reference**: Because they are migrations, each `aggregated_XYZ_migrations.rb` file has a timestamp prefixed to its name. That prefix follows the structure `10[two digits for the order]0[squashed version number]`. The order is necessary to ensure that dependencies are resolved. E.g. if a module adds a foreign key to a table of the core, the module needs to run after the core. Additionally, the order digits lead to unique names for the migration.
- **File inherits from `SquashedMigration`**: The aggregation files inherit from the `SquashedMigration` superclass which in turn inherits from `ActiveRecord::Migration`. `SquashedMigration` comes with the necessary structure for describing the targeted structure as well as ensuring that the correct structure is migrated from. 
- **`squashed_migrations` list**: Within each `aggregated_XYZ_migrations.rb` file, the `squashed_migrations` list the names of the migrations that are squashed by the file. This does only include the migrations squashed in this version. Migrations already squashed before will not be mentioned any more. E.g. The `1000016_aggregated_migrations.rb` file will reference all migrations squashed when moving from OP 16 to OP 17 but not those squashed in OP 16.
- **`tables` list**: Within each `aggregated_XYZ_migrations.rb` file, the `tables` list references all database tables (including columns, indices, constraints, ...) to be created. Each table receives its own file so that a file remains easily manageable. The table is described in full. Though changes to the table that come after the squashed state would not be included. A table file should always be in the module (or core) where the model file is located as well.
- **`extensions` list**: Within each `aggregated_XYZ_migrations.rb` file, the `extensions` list references all database extensions to create. Those could be index mechanisms like `pg_trgm` or collations. Extensions are loaded first so that tables can access the extensions on their turn.
- **`modifications` block**: Plugins can decide to modify a table via the `modifications` section in their `aggregated_XYZ_migrations.rb` file but that is an exemption. It makes sense to separate the modifications like this if the functionality strongly belongs into the module and is not used anywhere else.

### The squashing process

When preparing for a new major version release, the following steps take place:

1. **Check rails version on `SquashedMigration`**: `SquashedMigration` inherits from `ActiveRecord::Migration[RAILS_VERSION]`. In case the Rails version was bumped between the OpenProject versions, this reference in the superclass has to be adapted. Changing the version reference might already change the resulting structure so check this before continuing.

2. **Prior aggregated migrations renamed**: Rename the timestamp part of each `aggregated_XYZ_migrations.rb` file so that it reflects the previous major version. E.g. on releasing OP 17.0, the `db/migrate/1000015_aggregated_migrations.rb` file would be renamed to `db/migrate/1000016_aggregated_migrations.rb`. If a module newly receives an aggregated_migrations file, add one and ensure that it does not conflict with the existing order digits. If an `aggregated_XYZ_migrations.rb` file exists, but no migrations need to be squashed, the file can be left untouched. It will not look 100% consistent but the effort is not worth it.

3. **Migrations deleted**: All migrations up to and including the last patch of the previous major version are squashed. For OpenProject 16, which requires migrating from version 15, all migrations up to and including the last patch of OpenProject 14 are squashed. The squashed migrations are listed in the `aggregated_migrations.rb` files (`squashed_migrations` method). The first file to list there is the renamed filename (from step 2). E.g. after renaming `1000015_aggregated_migrations.rb` to `1000016_aggregated_migrations.rb`, the first item in the `squashed_migrations` list would be `1000015_aggregated_migrations`. After that, the file name of the other squashed migrations follow (although the order is not important). It is easier to remove migrations one at a time, so to carry out steps 4 - 7 for each squashed and therefore deleted migration file completely before moving to the next migration file to squash/delete.

4. **Create or adapt table classes**: Each database table is defined in a dedicated class in the `db/migrate/tables/` directory (or accordingly in a module). For example, `Tables::Announcements` defines the structure of the `announcements` table. When removing a squashed migration, move all table changes and creations into the appropriate table file. In some scenarios, when the columns strictly belong to a module, it makes sense to keep changes to a table in the `modifications` section of the module's aggregation file.

5. **Create or adapt extensions**: Each extension is defined in a dedicated class in the `db/migrate/extensions/` directory (or accordingly in a module). When removing a squashed migration, move all extensions (i.e. indices and collations) into an appropriate extension file.

6. **Ignore data changes**: Oftentimes, migration files not only include changes to the database structure but also include statements to move existing data from the old structure to the new. This code is no longer necessary as the `aggregated_XYZ_migrations` files only describe the database structure.

7. **Remove no longer referenced code**: Especially with data migrations, code in the application is sometimes referenced that after removing the migration is not referenced from anywhere else. This includes background jobs, libraries but could also be services or scopes. If they are not longer referenced from anywhere else, remove them.

8. **Minimum version is updated**: The `minimum_version` in the `SquashedMigration` class is increased to reflect the new required version for migration. For OP 16, that would be 15, for OP 17, that would be 16.

## Verifying the squashing process

To ensure that the squashing process hasn't introduced any schema changes, you can follow these steps:

1. Before squashing, run: `rails db:drop db:create db:migrate`
2. Rename the generated `db/structure.sql` file to something like `structure_unsquashed.sql`
3. Perform the squashing process
4. Run `rails db:drop db:create db:migrate` again to generate a new `structure.sql` file
5. Compare the two structure files (e.g., using `diff`) - there should be no differences. This includes known shortcomings. The shortcomings could be addressed in separate migrations.

To also ensure that the data hasn't changed, it is ideal to find a database that has data in it. With that found, follow these steps:

1. Create a dump of the database you want to run the comparison for, including data: `pg_dump --column-inserts -U [user_name] -d [database_name] > [database_name]-orig.sql`
2. Load the dump into the database you want to run the comparison on `psql [another_database_name] < [database_name]-orig.sql`
3. Switch to a commit prior to the migration squashing, e.g. by switching to the dev branch.
4. Run `rails db:migrate`
5. Export the dump `pg_dump --column-inserts -U [user_name] -d [another_database_name] > [database_name]-dev.sql`
6. Drop and recreate the database `rails db:drop db:create`
7. Switch to a commit after the migration squashing is introduced.
8. Load the original dump `psql [another_database_name] < [database_name]-orig.sql`
9. Run `rails db:migrate`
10. Export the dump `pg_dump --column-inserts -U [user_name] -d [another_database_name] > [database_name]-squashed.sql`
11. Run `git diff [database_name]-dev.sql [database_name]-squashed.sql`

## Particularities

good_job creates migration files when it is upgraded. It does so simply by looking for the existence of migration files with expected names. Removing the files as it is done for other migrations would therefore only lead to the file being recreated with a different timestamp once good_job is upgraded. To prevent that from happening, good_job's migration files are not removed. But they are emptied out and their contents moved to `tables` classes just like it is done for squashed migrations.
