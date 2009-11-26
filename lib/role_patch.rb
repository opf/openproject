require_dependency 'user'

# Patches Redmine's Users dynamically.
module RolePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable

      unless instance_methods.include? "allowed_to_without_inheritance?"
        alias_method_chain :allowed_to?, :inheritance
      end
    end

  end

  module ClassMethods
    def self.enclosed_permissions(permission_name)
      # FIXME: Remove me!
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
    def allowed_to_with_inheritance?(action)
      return true if allowed_to_without_inheritance?(action)

      if action.is_a? Hash
        # action is a parameter hash

        # check the action based on the permissions of the role and all
        # included permissions
        allowed_inherited_actions.include? "#{action[:controller]}/#{action[:action]}"
      else
        # check, if the role has one of the parent permissions granted
        permission = Redmine::AccessControl.permission(action)
        permission.inherited_by.detect {|parent| allowed_inherited_permissions.include? parent}

        # if parents = self.class.permission_tree[action]
        #   parents = [parents] unless parents.is_a? Array
        #   parents.each {|parent| return true if allowed_to? parent, for_user}
        # end
        # 
        # # check, if the current user can see the own objects of for_user
        # if personal = personal_permissions[action]
        #   return true if ((for_user == User.current) && allowed_to?(personal, nil))
        # end
      end
    end
    
  private
    def allowed_inherited_permissions
      @allowed_inherited_permissions ||= begin
        all_permissions = allowed_permissions || []
        (all_permissions | allowed_permissions.collect do |sym| 
          p = Redmine::AccessControl.permission(sym)
          p ? p.inherits.collect(&:name) : []
        end.flatten).uniq
      end
    end
    
    def allowed_inherited_actions
      @actions_allowed_inherited ||= begin
        allowed_inherited_permissions.inject({}){|actions, p| actions[p] = Redmine::AccessControl.allowed_actions(p); actions}
      end
    end
  end
end
