module Authorization
  class AllowedInEntityQuery
    attr_reader :user, :permissions, :entities

    def initialize(user, permissions, entity_or_entities)
      @user = user
      @permissions = Array(permissions)
      @entities = Array(entity_or_entities)
    end

    def query
      Role
        .joins(:role_permissions)
        .where(role_permissions: { permission: permission_names })
        .joins(member_roles: :member)
        # TODO: Check modules, built in roles, etc
        .where(members: { principal: user, entity: entities })
    end

    delegate :exists?, to: :query

    private

    def permission_names
      @permission_names ||= permissions.map(&:name)
    end
  end
end
