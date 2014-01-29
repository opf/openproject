class AddActiveToExportCardConfigurations < ActiveRecord::Migration
  def change
    add_column :export_card_configurations, :active, :boolean, default: true
  end
end
