require_dependency 'group'

# Patches Redmine's Groups dynamically.
module GroupPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable
    end

  end

  module ClassMethods
  end

  module InstanceMethods
    # Return group's roles for project
    def roles_for_project(project)
      roles = []
      # No role on archived projects
      return roles unless project && project.active?

      # Find project membership
      membership = memberships.detect {|m| m.project_id == project.id}
      if membership
        roles = membership.roles
      else
        @role_non_member ||= Role.non_member
        roles << @role_non_member
      end
      roles
    end
  
  
    def allowed_to?(action, project, options={})
      # we just added to user parameter to the calls to role.allowed_to?
      
      if project
        # No action allowed on archived projects
        return false unless project.active?
        # No action allowed on disabled modules
        return false unless project.allows_to?(action)

        roles = roles_for_project(project)
        return false unless roles
        roles.detect {|role| (project.is_public? || role.member?) && role.allowed_to?(action, options[:for_user])}

      elsif options[:global]
        # authorize if group has at least one role that has this permission
        roles = memberships.collect {|m| m.roles}.flatten.uniq
        roles.detect {|r| r.allowed_to?(action, options[:for_user])} || (self.logged? ? Role.non_member.allowed_to?(action, options[:for_user]) : Role.anonymous.allowed_to?(action, options[:for_user]))
      else
        false
      end
    end
  
  
  
  end
end
