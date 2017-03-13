require_relative './20170116105342_add_custom_options'

##
# A bug in the AddCustomOptions migration was fixed because of which not
# all list custom field values were migrated correctly.
# The missed values can be simply migrated by calling the fixed code
# which is all this migration does.
class MigrateMissedListCustomValues < ActiveRecord::Migration[5.0]
  def up
    migration = AddCustomOptions.new

    migration.migrate_all_values!
  end

  def down
    # No down migration is necessary as it wil be handled in the original
    # AddCustomOptions migration.
  end
end
