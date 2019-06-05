class RemoveInAggregationFromType < ActiveRecord::Migration[5.1]
  def change
    remove_column :types, :in_aggregation, :boolean, default: true, null: false
  end
end
