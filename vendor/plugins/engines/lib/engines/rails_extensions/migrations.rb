# Contains the enhancements to Rails' migrations system to support the 
# Engines::Plugin::Migrator. See Engines::RailsExtensions::Migrations for more
# information.

require "engines/plugin/migrator"

# = Plugins and Migrations: Background
#
# Rails uses migrations to describe changes to the databases as your application
# evolves. Each change to your application - adding and removing models, most
# commonly - might require tweaks to your schema in the form of new tables, or new
# columns on existing tables, or possibly the removal of tables or columns. Migrations
# can even include arbitrary code to *transform* data as the underlying schema
# changes.
# 
# The point is that at any particular stage in your application's development, 
# migrations serve to transform the database into a state where it is compatible
# and appropriate at that time.
# 
# == What about plugins?
# 
# If you want to share models using plugins, chances are that you might also
# want to include the corresponding migrations to create tables for those models.
# With the engines plugin installed, plugins can carry migration data easily:
# 
#   vendor/
#     |
#     plugins/
#       |
#       my_plugin/
#         |- init.rb
#         |- lib/
#         |- db/
#             |-migrate/
#                 |- 20081105123419_add_some_new_feature.rb
#                 |- 20081107144959_and_something_else.rb
#                 |- ...
# 
# When you install a plugin which contains migrations, you are undertaking a
# further step in the development of your application, the same as the addition
# of any other code. With this in mind, you may want to 'roll back' the
# installation of this plugin at some point, and the database should be able
# to migrate back to the point without this plugin in it too.
#
# == An example
#
# For example, our current application is at version 20081106164503 (according to the
# +schema_migrations+ table), when we decide that we want to add a tagging plugin. The
# tagging plugin chosen includes migrations to create the tables it requires
# (say, _tags_ and _taggings_, for instance), along with the models and helpers
# one might expect.
#
# After installing this plugin, these tables should be created in our database.
# Rather than running the migrations directly from the plugin, they should be
# integrated into our main migration stream in order to accurately reflect the
# state of our application's database *at this moment in time*.
#
#   $ script/generate plugin_migration
#         exists  db/migrate
#         create  db/migrate/20081108120415_my_plugin_to_version_20081107144959.rb
#
# This migration will take our application to version 20081108120415, and contains the 
# following, typical migration code:
# 
#   class TaggingToVersion20081107144959 < ActiveRecord::Migration
#     def self.up
#       Engines.plugins[:tagging].migrate(20081107144959)
#     end
#     def self.down
#       Engines.plugins[:tagging].migrate(0)
#     end
#   end
#
# When we migrate our application up, using <tt>rake db:migrate</tt> as normal,
# the plugin will be migrated up to its latest version (20081108120415 in this example). If we
# ever decide to migrate the application back to the state it was in at version 20081106164503,
# the plugin migrations will be taken back down to version 0 (which, typically,
# would remove all tables the plugin migrations define).
#
# == Upgrading plugins
#
# It might happen that later in an application's life, we update to a new version of
# the tagging plugin which requires some changes to our database. The tagging plugin
# provides these changes in the form of its own migrations. 
#
# In this case, we just need to re-run the plugin_migration generator to create a 
# new migration from the current revision to the newest one:
#
#   $ script/generate plugin_migration
#        exists db/migrate
#        create db/migrate/20081210131437_tagging_to_version_20081201172034.rb
#
# The contents of this migration are:
#
#   class TaggingToVersion20081108120415 < ActiveRecord::Migration
#     def self.up
#       Engines.plugins[:tagging].migrate(20081201172034)
#     end
#     def self.down
#       Engines.plugins[:tagging].migrate(20081107144959)
#     end
#   end
#
# Notice that if we were to migrate down to revision 20081108120415 or lower, the tagging plugin
# will be migrated back down to version 20081107144959 - the version we were previously at.
#
#
# = Creating migrations in plugins
#
# In order to use the plugin migration functionality that engines provides, a plugin 
# only needs to provide regular migrations in a <tt>db/migrate</tt> folder within it.
#
# = Explicitly migrating plugins
#
# It's possible to migrate plugins within your own migrations, or any other code.
# Simply get the Plugin instance, and its Plugin#migrate method with the version
# you wish to end up at:
#
#   Engines.plugins[:whatever].migrate(version)
#
#
# = Upgrading from previous versions of the engines plugin
#
# Thanks to the tireless work of the plugin developer community, we can now relying on the migration 
# mechanism in Rails 2.1+ to do much of the plugin migration work for us. This also means that we
# don't need a seperate schema_info table for plugins.
#
# To update your application, run
#
#   rake db:migrate:upgrade_plugin_migrations
#
# This will ensure that migration information is carried over into the main schema_migrations table.
# 