module Authorization
  class UserPermissibleService
    attr_accessor :user

    def initialize(user)
      @user = user
      @cached_permissions = Hash.new do |hash, key|
        hash[key] = Set.new
      end
    end

    def allowed_globally?(permission)
      perms = Authorization.contextual_permissions(permission, :global, raise_on_unknown: true)
      return true if admin_and_all_granted_to_admin?(perms)

      cached_permissions(:global).intersect?(perms.map(&:name))
    end

    def allowed_in_project?(permission, projects_to_check)
      perms = Authorization.contextual_permissions(permission, :project, raise_on_unknown: true)
      return false if projects_to_check.blank?
      return false unless authorizable_user?

      projects = Array(projects_to_check)

      projects.all? do |project|
        allowed_in_single_project?(perms, project)
      end
    end

    def allowed_in_any_project?(permission)
      perms = Authorization.contextual_permissions(permission, :project, raise_on_unknown: true)
      return true if admin_and_all_granted_to_admin?(perms)

      Project.allowed_to(user, perms).exists?
    end

    def allowed_in_entity?(permission, entities_to_check, entity_class)
      return false if entities_to_check.blank?
      return false unless authorizable_user?

      context = entity_class.model_name.element.to_sym
      perms = Authorization.contextual_permissions(permission, context, raise_on_unknown: true)

      entities = Array(entities_to_check)

      entities.all? do |entity|
        allowed_in_single_entity?(perms, entity)
      end
    end

    def allowed_in_any_entity?(permission, entity_class, in_project: nil)
      context = entity_class.model_name.element.to_sym
      perms = Authorization.contextual_permissions(permission, context, raise_on_unknown: true)
      return true if admin_and_all_granted_to_admin?(perms)

      if in_project
        WorkPackage.allowed_to(user, perms).exists?(project: in_project)
      else
        WorkPackage.allowed_to(user, perms).exists?
      end
    end

    private

    def cached_permissions(context)
      unless @cached_permissions.key?(context)
        @cached_permissions[context] = if context == :global
                                         global_permissions
                                       elsif context.is_a?(Project)
                                         project_permissions(context)
                                       else
                                         entity_permissions(context)
                                       end
      end

      @cached_permissions[context]
    end

    def allowed_in_single_project?(permissions, project)
      return false if project.nil?
      return false unless project.active? || project.being_archived?

      permissions_filtered_for_project = project.allowed_permissions.intersection(permissions.map(&:name))

      return false if permissions_filtered_for_project.empty?
      return true if admin_and_all_granted_to_admin?(permissions)

      cached_permissions(project).intersect?(permissions_filtered_for_project.map(&:name))
    end

    def allowed_in_single_entity?(permissions, entity)
      return false if entity.nil?

      permissions_filtered_for_project = entity.project.allowed_permissions.intersection(permissions.map(&:name))

      return false if permissions_filtered_for_project.empty?
      return true if admin_and_all_granted_to_admin?(permissions)
      return true if allowed_in_single_project?(permissions, entity.project)

      cached_permissions(entity).intersect?(permissions_filtered_for_project.map(&:name))
    end

    def admin_and_all_granted_to_admin?(permissions)
      user.admin? && permissions.all?(&:grant_to_admin?)
    end

    def authorizable_user?
      !user.locked? || user.is_a?(SystemUser)
    end

    def global_permissions
      RolePermission
        .joins(role: { member_roles: :member })
        .where(members: { user_id: user.id, entity: nil, project: nil })
        .pluck(:permission)
        .map(&:to_sym)
    end

    def project_permissions(project)
      RolePermission
        .joins(role: { member_roles: :member })
        .where(members: { user_id: user.id, entity: nil, project: })
        .pluck(:permission)
        .map(&:to_sym)
        .select { |permission| project.allows_to?(permission) }
    end

    def entity_permissions(entity)
      RolePermission
        .joins(role: { member_roles: :member })
        .where(members: { user_id: user.id, entity:, project: entity.porject })
        .pluck(:permission)
        .map(&:to_sym)
        .select { |permission| entity.project.allows_to?(permission) }
    end
  end
end
