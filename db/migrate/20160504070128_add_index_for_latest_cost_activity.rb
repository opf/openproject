class AddIndexForLatestCostActivity < ActiveRecord::Migration
  def change
    add_index :cost_objects, [:project_id, :updated_on]
  end
end
