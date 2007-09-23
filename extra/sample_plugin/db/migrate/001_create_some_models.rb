# Sample plugin migration
# Use rake db:migrate_plugins to migrate installed plugins
class CreateSomeModels < ActiveRecord::Migration
  def self.up
    create_table :example_plugin_model, :force => true do |t|
      t.column "example_attribute", :integer
    end
  end

  def self.down
    drop_table :example_plugin_model
  end
end
