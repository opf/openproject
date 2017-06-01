class RemoveLegacyTables < ActiveRecord::Migration[5.0]
  def up
    drop_table(:legacy_default_planning_element_types, if_exists: true)
    drop_table(:legacy_enabled_planning_element_types, if_exists: true)
    drop_table(:legacy_issues, if_exists: true)
    drop_table(:legacy_journals, if_exists: true)
    drop_table(:legacy_planning_element_types, if_exists: true)
    drop_table(:legacy_planning_elements, if_exists: true)
    drop_table(:legacy_user_identity_urls, if_exists: true)
  end

  # Down migration is not interesting as the data has been lost already
end
