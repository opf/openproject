module Authorization
  class UserPermissibleService
    attr_accessor :user

    def initialize(user)
      @user = user
    end

    def allowed_globally?(permission)
      perms = contextual_permissions(permission, :global)
      return false unless authorizable_user?
      return true if admin_and_all_granted_to_admin?(perms)

      cached_permissions(nil).intersect?(perms.map(&:name))
    end

    def allowed_in_project?(permission, projects_to_check)
      perms = contextual_permissions(permission, :project)
      return false if projects_to_check.blank?
      return false unless authorizable_user?

      projects = Array(projects_to_check)

      projects.all? do |project|
        allowed_in_single_project?(perms, project)
      end
    end

    def allowed_in_any_project?(permission)
      perms = contextual_permissions(permission, :project)
      return false unless authorizable_user?
      return true if admin_and_all_granted_to_admin?(perms)

      cached_in_any_project?(perms)
    end

    def allowed_in_entity?(permission, entities_to_check, entity_class)
      return false if entities_to_check.blank?
      return false unless authorizable_user?

      perms = contextual_permissions(permission, context_name(entity_class))

      entities = Array(entities_to_check)

      entities.all? do |entity|
        allowed_in_single_entity?(perms, entity)
      end
    end

    def allowed_in_any_entity?(permission, entity_class, in_project: nil) # rubocop:disable Metrics/PerceivedComplexity
      perms = contextual_permissions(permission, context_name(entity_class))
      return false unless authorizable_user?
      return false if in_project && !(in_project.active? || in_project.being_archived?)
      return true if admin_and_all_granted_to_admin?(perms)

      # entity_class.allowed_to will also check whether the user has the permission via a membership in the project.
      # ^-- still a problem in some cases
      allowed_scope = entity_class.allowed_to(user, perms)

      if in_project
        allowed_in_single_project?(perms, in_project) || allowed_scope.exists?(project: in_project)
      else
        allowed_in_any_project?(perms) || allowed_scope.exists?
      end
    end

    private

    def cached_permissions(context)
      @cached_permissions ||= Hash.new do |hash, context_key|
        hash[context_key] = user.all_permissions_for(context_key)
      end

      @cached_permissions[context]
    end

    def cached_in_any_project?(permissions)
      @any_project_cache ||= Hash.new do |hash, perm|
        hash[perm] = Project.allowed_to(user, perm).exists?
      end

      permissions.any? { |permission| @any_project_cache[permission] }
    end

    def allowed_in_single_project?(permissions, project)
      return false if project.nil?
      return false unless project.active? || project.being_archived?

      permissions_filtered_for_project = permissions_by_enabled_project_modules(project, permissions)

      return false if permissions_filtered_for_project.empty?
      return true if admin_and_all_granted_to_admin?(permissions)

      cached_permissions(project).intersect?(permissions_filtered_for_project)
    end

    def allowed_in_single_entity?(permissions, entity)
      return false if entity.nil?
      return false if entity.project.nil?
      return false unless entity.project.active? || entity.project.being_archived?

      permissions_filtered_for_project = permissions_by_enabled_project_modules(entity.project, permissions)

      return false if permissions_filtered_for_project.empty?
      return true if admin_and_all_granted_to_admin?(permissions)

      # The combination of this is better then doing
      # EntityClass.allowed_to(user, permission).exists?.
      # Because this way, all permissions for that context are fetched and cached.
      allowed_in_single_project?(permissions, entity.project) ||
        cached_permissions(entity).intersect?(permissions_filtered_for_project)
    end

    def admin_and_all_granted_to_admin?(permissions)
      user.admin? && permissions.all?(&:grant_to_admin?)
    end

    def authorizable_user?
      !user.locked? || user.is_a?(SystemUser)
    end

    def permissions_by_enabled_project_modules(project, permissions)
      project
        .allowed_permissions
        .intersection(permissions.map(&:name))
        .map { |perm| perm.name.to_sym }
    end

    def contextual_permissions(permission, context)
      Authorization.contextual_permissions(permission, context, raise_on_unknown: true)
    end

    def context_name(entity_class)
      entity_class.model_name.element.to_sym
    end
  end
end
