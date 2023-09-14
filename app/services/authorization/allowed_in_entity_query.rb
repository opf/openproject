module Authorization
  class AllowedInEntityQuery
    attr_reader :user, :permissions, :entity

    def initialize(user, permissions, entity)
      @user = user
      @permissions = Array(permissions)
      @entity = entity
    end

    def query
      Role
        .joins(:role_permissions)
        .where(role_permissions: { permission: permission_names })
        .joins(member_roles: :member)
        # TODO: Check modules, built in roles, etc
        .where(members: { principal: user, project_id: entity.project_id, entity: })
    end

    delegate :exists?, to: :query

    private

    def permission_names
      @permission_names ||= permissions.map(&:name)
    end
  end
end
