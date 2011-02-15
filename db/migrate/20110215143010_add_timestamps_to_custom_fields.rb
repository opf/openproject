class AddTimestampsToCustomFields < ActiveRecord::Migration
  def self.up
    add_timestamps :custom_fields
  end

  def self.down
    remove_timestamps :custom_fields
  end
end
