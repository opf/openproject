class RefactorTerms < ActiveRecord::Migration
  def self.up
    rename_table :deliverable_costs, :material_budget_items
    rename_column :material_budget_items, :deliverable_id, :cost_object_id

    rename_table :deliverable_hours, :labor_budget_items
    rename_column :labor_budget_items, :deliverable_id, :cost_object_id
    
    rename_table :deliverables, :cost_objects
    
    execute("UPDATE cost_objects SET type = 'CostObject' WHERE cost_objects.type = 'Deliverable'")
    execute("UPDATE cost_objects SET type = 'VariableCostObject' WHERE cost_objects.type = 'CostBasedDeliverable'")
    execute("UPDATE cost_objects SET type = 'FixedCostObject' WHERE cost_objects.type = 'FixedDeliverable'")
    
    rename_column :issues, :deliverable_id, :cost_object_id
    
    Role.find(:all).each do |role|
      rename_permission(role, :view_deliverables, :view_cost_objects)
      rename_permission(role, :edit_deliverables, :edit_cost_objects)
      role.save!
    end
  end
  
  def self.down
    rename_table :material_budget_items, :deliverable_costs
    rename_column :material_budget_items, :cost_object_id, :deliverable_id

    rename_table :labor_budget_items, :deliverable_hours
    rename_column :labor_budget_items, :cost_object_id, :deliverable_id
    
    rename_table :cost_objects, :deliverables
    execute("UPDATE deliverables SET type = 'Deliverable' WHERE deliverables.type = 'CostObject'")
    execute("UPDATE deliverables SET type = 'CostBasedDeliverable' WHERE deliverables.type = 'VariableCostObject'")
    execute("UPDATE deliverables SET type = 'FixedDeliverable' WHERE deliverables.type = 'FixedCostObject'")

    rename_column :issues, :deliverable_id, :cost_object_id

    


    Role.find(:all).each do |role|
      rename_permission(role, :view_cost_objects, :view_deliverables)
      rename_permission(role, :edit_cost_objects, :edit_deliverables)
      role.save!
    end
  end
  
  def self.rename_permission(role, old_perm, new_perm)
    if role.has_permission?(old_perm)
      perms = role.permissions
      
      perms.delete(old_perm.to_sym)
      perms << new_perm.to_sym
      
      role.permissions = perms
    end
  end
end
