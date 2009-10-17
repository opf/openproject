class AddMissingIndexesToCustomFieldsTrackers < ActiveRecord::Migration
  def self.up
    add_index :custom_fields_trackers, [:custom_field_id, :tracker_id]
  end

  def self.down
    remove_index :custom_fields_trackers, :column => [:custom_field_id, :tracker_id]
  end
end
