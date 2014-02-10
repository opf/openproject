class AddDescriptionToExportCardConfigurations < ActiveRecord::Migration
  def change
    add_column :export_card_configurations, :description, :text
  end
end
