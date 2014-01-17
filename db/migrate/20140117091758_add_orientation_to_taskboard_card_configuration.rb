class AddOrientationToTaskboardCardConfiguration < ActiveRecord::Migration
  def change
    add_column :taskboard_card_configurations, :orientation, :string
  end
end
