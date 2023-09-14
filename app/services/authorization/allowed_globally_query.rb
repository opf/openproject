module Authorization
  class AllowedGloballyQuery
    attr_reader :user, :permissions

    def initialize(user, permissions)
      @user = user
      @permissions = Array(permissions)
    end

    def query
      Member
        .where(principal: user, project: nil, entity: nil)
        .joins({ member_roles: { role: :role_permissions } })
        .where(role_permissions: { permission: permission_names })
    end

    delegate :exists?, to: :query

    private

    def permission_names
      @permission_names ||= permissions.map(&:name)
    end
  end
end
