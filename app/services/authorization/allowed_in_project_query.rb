module Authorization
  class AllowedInProjectQuery
    attr_reader :user, :permissions, :projects

    def initialize(user, permissions, project_or_projects)
      @user = user
      @permissions = Array(permissions)
      @projects = Array(project_or_projects)
    end

    def query
      Role
        .joins(:role_permissions)
        .where(role_permissions: { permission: permission_names })
        .joins(member_roles: :member)
        # TODO: Check modules, built in roles, etc
        .where(members: { principal: user, project: projects, entity: nil })
    end

    delegate :exists?, to: :query

    private

    def permission_names
      @permission_names ||= permissions.map(&:name)
    end
  end
end
