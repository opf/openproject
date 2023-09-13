module Authorization
  class UnknownPermissionError < StandardError
    def initialize(permission_name)
      super("Tried to check permission #{permission_name} that is not defined as a valid permission. It will never return true")
    end
  end

  class IllegalPermissionCheck < StandardError
    def initialize(permission, permissions, context)
      super("Tried to check permission #{permission} in #{context} context. Permissible contexts for this permission are: #{permissions.flat_map(&:permissible_on).uniq.join(', ')}.")
    end
  end

  class UserPermissibleService
    attr_accessor :user

    def initialize(user, role_cache: Users::ProjectRoleCache.new(user))
      @user = user
      @project_role_cache = role_cache
    end

    def allowed_globally?(permission)
      perms = normalized_permissions(permission, :global)
      return true if admin_and_all_granted_to_admin?(perms)

      AllowedGloballyQuery.new(user, perms).exist?
    end

    def allowed_in_project?(permission, project)
      perms = normalized_permissions(permission, :project)
      return true if admin_and_all_granted_to_admin?(perms)

      AllowedInProjectQuery.new(user, project, perms).exist?
    end

    def allowed_in_any_project?(permission)
      perms = normalized_permissions(permission, :project)
      return true if admin_and_all_granted_to_admin?(perms)

      AllowedInAnyProjectQuery.new(user, perms).exist?
    end

    def allowed_in_entity?(permission, entity)
      context = entity.model_name.element.to_sym
      perms = normalized_permissions(permission, context)
      return true if admin_and_all_granted_to_admin?(perms)

      AllowedInEntityQuery.new(user, entity, perms).exist?
    end

    def allowed_in_any_entity?(permission, entity_class, in_project: nil)
      context = entity_class.model_name.element.to_sym
      perms = normalized_permissions(permission, context)
      return true if admin_and_all_granted_to_admin?(perms)

      AllowedInAnyEntityQuery.new(user, entity_class, perms, in_project:).exist?
    end

    private

    def normalized_permissions(permission, context)
      perms = if permission.is_a?(Hash)
                OpenProject::AccessControl.allow_actions(permission)
              else
                [OpenProject::AccessControl.permission(permission)].compact
              end

      raise UnknownPermissionError.new(permission) if perms.blank?

      context_perms = perms.select { |p| p.permissible_on?(context) }
      raise IllegalPermissionCheck.new(permission, perms, context) if context_perms.blank?

      context_perms
    end

    def admin_and_all_granted_to_admin?(perms)
      user.admin? && perms.all?(&:granted_to_admin?)
    end
  end
end
