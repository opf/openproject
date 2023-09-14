module Authorization
  class AllowedInProjectQuery
    attr_reader :user, :permissions, :project

    def initialize(user, permissions, project)
      @user = user
      @permissions = Array(permissions)
      @project = project
    end

    def query
      Role
        .joins(:role_permissions)
        .where(role_permissions: { permission: permission_names })
        .joins(member_roles: :member)
        # TODO: Check modules, built in roles, etc
        .where(members: { principal: user, project:, entity: nil })
    end

    delegate :exists?, to: :query

    private

    def permission_names
      @permission_names ||= permissions.map(&:name)
    end
  end
end
