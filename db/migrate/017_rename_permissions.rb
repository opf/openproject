class RenamePermissions < ActiveRecord::Migration
  @@renaming = {
    :view_own_rate => :view_own_hourly_rate,
    :view_all_rates => :view_hourly_rates,
    :change_rates => :edit_hourly_rates,
    
    :view_unit_price => :view_cost_rates,
    :book_own_costs => :log_own_costs,
    :book_costs => :log_costs,
  }
  cattr_reader :renaming
  
  def self.up
    transaction do
      Role.all.each do |role|
        renaming.each_pair do |from, to|
          rename_permission(role, from, to)
          role.save!
        end
      end
    end
  end
  
  def self.down
    transaction do
      Role.all.each do |role|
        renaming.each_pair do |to, from|
          rename_permission(role, from, to)
          role.save!
        end
      end
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