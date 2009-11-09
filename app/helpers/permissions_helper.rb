module PermissionsHelper
  def self.included(base) # :nodoc:
    # Same as typing in the class 
    base.class_eval do
      @@permission_tree = {
        :view_own_time_entries => [:view_time_entries, :change_own_time_entries], 
        :view_time_entries => [:change_time_entries, :view_cost_objects],
        :change_own_time_entries => :change_time_entries,

        :log_own_time => :log_time,
        :log_own_costs => :log_costs,

        :view_own_rates => [:view_all_rates, :change_own_rate],
        :view_all_rates => [:change_all_rates, :view_cost_objects],
        :change_own_rate => :change_all_rates,

        :view_own_cost_entries => [:view_cost_entries, :change_own_cost_entries],
        :view_cost_entries => [:change_cost_entries, :view_cost_objects],
        :change_own_cost_entries => :change_cost_entries,

        :view_unit_price => :view_cost_objects,

        :view_cost_objects => :edit_cost_objects,
      }
      cattr_reader :permission_tree

      @@personal_permissions = {
        :view_time_entries => :view_own_time_entries,
        :view_cost_entries => :view_own_cost_entries,
        :view_all_rates => :view_own_rate,

        :change_time_entries => :change_own_time_entries,
        :change_cost_entries => :change_own_cost_entries,
        :change_all_rates => :change_own_rate,

        :log_time => :log_own_time,
        :log_costs => :log_own_costs
      }
      cattr_reader :personal_permissions
    end
  end
  
  def user_allowed_to?(action, personal_user = nil)
    p @project

    if @project
      return true if User.current.allowed_to?(action, @project)
    else
      return true if User.current.allowed_to?(action, nil, :global => true)
    end
    
    puts "--------------------------------------"
    
    if parents = self.class.permission_tree[action]
      parents = [parents] unless parents.is_a? Array
      parents.each {|p| return true if user_allowed_to? p }
    end
    
    if personal = personal_permissions[action]
      return true if (personal_user == User.current && user_allowed_to?(personal))
    end

    return false
  end
end
