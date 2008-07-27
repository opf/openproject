# Sample plugin migration
# Use rake db:migrate_plugins to migrate installed plugins
class CreateMeetings < ActiveRecord::Migration
  def self.up
    create_table :meetings do |t|
      t.column :project_id, :integer, :null => false
      t.column :description, :string
      t.column :scheduled_on, :datetime
    end
  end

  def self.down
    drop_table :meetings
  end
end
