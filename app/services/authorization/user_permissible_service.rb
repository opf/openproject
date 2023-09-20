module Authorization
  class UnknownPermissionError < StandardError
    def initialize(permission_name)
      super("Tried to check permission #{permission_name} that is not defined as a valid permission. It will never return true")
    end
  end

  class IllegalPermissionCheck < StandardError
    def initialize(permission, permissions, context)
      super("Tried to check permission #{permission} which maps to #{permissions.map(&:name).join(', ')} in #{context} context. Permissible contexts for this permission are: #{permissions.flat_map(&:permissible_on).uniq.join(', ')}.")
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

      AllowedGloballyQuery.new(user, perms).exists?
    end

    def allowed_in_project?(permission, projects_to_check)
      perms = normalized_permissions(permission, :project)
      return false if projects_to_check.blank?
      return false unless authorizable_user?
      return true if admin_and_all_granted_to_admin?(perms)

      projects = Array(projects_to_check)

      projects.all? do |project|
        allowed_in_single_project?(permission, project)
      end
    end

    def allowed_in_any_project?(permission)
      perms = normalized_permissions(permission, :project)
      return true if admin_and_all_granted_to_admin?(perms)

      AllowedInAnyProjectQuery.new(user, perms).exists?
    end

    def allowed_in_entity?(permission, entities_to_check)
      return false if entities_to_check.blank?
      return false unless authorizable_user?

      entities = Array(entities_to_check)

      entities.all? do |entity|
        allowed_in_single_entity?(permission, entity)
      end
    end

    def allowed_in_any_entity?(permission, entity_class, in_project: nil)
      context = entity_class.model_name.element.to_sym
      perms = normalized_permissions(permission, context)
      return true if admin_and_all_granted_to_admin?(perms)

      AllowedInAnyEntityQuery.new(user:, permissions: perms, entity_class:, in_project:).exists?
    end

    def self.permissions_for(action)
      return [action] if action.is_a?(OpenProject::AccessControl::Permission)
      return action if action.is_a?(Array) && action.all? { |a| a.is_a?(OpenProject::AccessControl::Permission) }

      if action.is_a?(Hash)
        if action[:controller]&.to_s&.starts_with?('/')
          action = action.dup
          action[:controller] = action[:controller][1..]
        end

        OpenProject::AccessControl.allow_actions(action)
      else
        [OpenProject::AccessControl.permission(action)].compact
      end
    end

    private

    def allowed_in_single_project?(permissions, project)
      return false unless project.active? || project.being_archived?

      AllowedInProjectQuery.new(user, project, permissions).exists?
    end

    def allowed_in_single_entity?(permissions, entity)
      context = entity.model_name.element.to_sym
      perms = normalized_permissions(permissions, context)

      return true if admin_and_all_granted_to_admin?(perms)

      if entity.respond_to?(:project)
        return false if entity.project.nil?
        return true if allowed_in_single_project?(perms, entity.project)
        return false unless entity.project.active? || entity.project.being_archived?
      end

      AllowedInEntityQuery.new(user:, entity:, permissions: perms).exists?
    end

    def normalized_permissions(permission, context)
      perms = self.class.permissions_for(permission)

      if perms.blank?
        Rails.logger.warn "Tried to check permission #{permission} that is not defined as a valid permission. It will never return true"
        # raise UnknownPermissionError.new(permission)
        return []
      end

      context_perms = perms.select { |p| p.permissible_on?(context) }
      raise IllegalPermissionCheck.new(permission, perms, context) if context_perms.blank?

      context_perms
    end

    def admin_and_all_granted_to_admin?(perms)
      user.admin? && perms.all?(&:grant_to_admin?)
    end

    def authorizable_user?
      !user.locked? || user.is_a?(SystemUser)
    end
  end
end
