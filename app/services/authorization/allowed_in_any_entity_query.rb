module Authorization
  class AllowedInAnyEntityQuery
    attr_reader :user, :permissions, :entity_class, :in_project

    def initialize(user:, permissions:, entity_class:, in_project: nil)
      @user = user
      @permissions = Array(permissions)
      @entity_class = entity_class
      @in_project = in_project
    end

    def query
      query = Role
        .joins(:role_permissions)
        .where(role_permissions: { permission: permission_names })
        .joins(member_roles: :member)
        .where(members: { principal: user, entity_type: entity_class.model_name.to_s })
        .where("members.project_id IS NOT NULL AND members.entity_id IS NOT NULL")

      if in_project
        query.where(members: { project_id: in_project.id })
      else
        query
      end
    end

    delegate :exists?, to: :query

    private

    def permission_names
      @permission_names ||= permissions.map(&:name)
    end
  end
end
