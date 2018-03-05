class AddIndexForLatestCostActivity < ActiveRecord::Migration[5.0]
  def change
    add_index :cost_objects, [:project_id, :updated_on]
  end
end
