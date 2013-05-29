class RemoveSignoffFromCostObjects < ActiveRecord::Migration
  def change
    remove_column :cost_objects, :project_manager_signoff
    remove_column :cost_objects, :client_signoff
  end
end
