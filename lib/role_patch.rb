require_dependency 'user'

# Patches Redmine's Users dynamically.
module RolePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable

      @@permission_tree = {
        :view_own_time_entries => [:view_time_entries, :edit_own_time_entries], 
        :view_time_entries => [:edit_time_entries, :view_cost_objects],
        :edit_own_time_entries => :edit_time_entries,

        :log_own_time => :log_time,
        :log_own_costs => :log_costs,

        :view_own_hourly_rates => [:view_hourly_rates, :edit_own_hourly_rate],
        :view_hourly_rates => [:edit_hourly_rates, :view_cost_objects],
        :edit_own_hourly_rate => :edit_hourly_rates,

        :view_own_cost_entries => [:view_cost_entries, :edit_own_cost_entries],
        :view_cost_entries => [:edit_cost_entries, :view_cost_objects],
        :edit_own_cost_entries => :edit_cost_entries,

        :view_cost_rates => :view_cost_objects,

        :view_cost_objects => :edit_cost_objects,
      }
      cattr_reader :permission_tree

      @@personal_permissions = {
        :view_time_entries => :view_own_time_entries,
        :view_cost_entries => :view_own_cost_entries,
        :view_hourly_rates => :view_own_hourly_rate,

        :change_time_entries => :change_own_time_entries,
        :change_cost_entries => :change_own_cost_entries,
        :change_hourly_rates => :change_own_hourly_rate,

        :log_time => :log_own_time,
        :log_costs => :log_own_costs
      }
      cattr_reader :personal_permissions

      unless instance_methods.include? "allowed_to_without_inheritance?"
        alias_method_chain :allowed_to?, :inheritance
      end
    end

  end

  module ClassMethods
    def self.enclosed_permissions(permission_name)
      sub_permissions = [permission_name]
      
      permission_tree.each_pair do |k, v|
        if (v == permission_name) || (v.is_a?(Array) && v.include?(permission_name))
          sub_permissions << enclosed_permissions(k)
        end
      end
      
      sub_permissions.flatten.uniq
    end
  end

  module InstanceMethods
    # Return true if the user is allowed to do the specified action on project
    # action can be:
    # * a parameter-like Hash (eg. :controller => 'projects', :action => 'edit')
    # * a permission Symbol (eg. :edit_project)
    def allowed_to_with_inheritance?(action, for_user=nil)
      return true if allowed_to_without_inheritance?(action)
      
      # set default user
      user = user || User.current
      
      if action.is_a? Hash
        # action is a parameter hash
        
        # check the action based on the permissions of the role and all
        # included permissions
        allowed_inherited_actions.include? "#{action[:controller]}/#{action[:action]}"
      else
        # action is a permission name
        
        # check, if the role has one of the parent permissions granted
        if parents = self.class.permission_tree[action]
          parents = [parents] unless parents.is_a? Array
          parents.each {|parent| return true if allowed_to? parent, for_user}
        end
        
        # check, if the current user can see the own objects of for_user
        if personal = personal_permissions[action]
          return true if ((for_user == User.current) && allowed_to?(personal, for_user))
        end
      end
      
      false
    end

  private
    def allowed_inherited_actions
      @actions_allowed ||= begin
        allowed_permissions.inject([]) do |all_actions, p|
          all_actions += self.class.enclosed_permissions(p).inject([]) do |actions, permission|
            actions += Redmine::AccessControl.allowed_actions(permission)
          end
        end.flatten
      end
    end
    
    
  end
end
