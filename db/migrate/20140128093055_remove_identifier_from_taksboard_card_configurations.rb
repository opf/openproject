class RemoveIdentifierFromTaksboardCardConfigurations < ActiveRecord::Migration
  def change
    remove_column :taskboard_card_configurations, :identifier
  end
end
