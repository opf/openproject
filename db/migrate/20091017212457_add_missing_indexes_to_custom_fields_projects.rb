class AddMissingIndexesToCustomFieldsProjects < ActiveRecord::Migration
  def self.up
    add_index :custom_fields_projects, [:custom_field_id, :project_id]
  end

  def self.down
    remove_index :custom_fields_projects, :column => [:custom_field_id, :project_id]
  end
end
