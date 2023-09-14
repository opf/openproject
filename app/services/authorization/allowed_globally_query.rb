module Authorization
  class AllowedGloballyQuery
    attr_reader :user, :permissions

    def initialize(user, permissions)
      @user = user
      @permissions = Array(permissions)
    end

    def query
      Role
        .joins(:role_permissions)
        .where(role_permissions: { permission: permission_names })
        .joins(member_roles: :member)
        .where(members: { principal: user, project: nil, entity: nil })
    end

    delegate :exists?, to: :query

    private

    def permission_names
      @permission_names ||= permissions.map(&:name)
    end
  end
end
