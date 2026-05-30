# frozen_string_literal: true

# Open access: every logged-in user can see and interact with all active
# projects and their work packages, regardless of membership or role.
# Anonymous users fall back to OpenProject's default visibility rules.

# ---------------------------------------------------------------------------
# Patch 1: Project.visible — project listing / navigation
# ---------------------------------------------------------------------------
module Mngt
  module ProjectVisiblePatch
    def visible(user = User.current)
      return active if user.logged? && !user.anonymous?

      super(user)
    end
  end
end

# ---------------------------------------------------------------------------
# Patch 2: Project.allowed_to_member_union — permission checks for projects
# AND work packages (WorkPackage.allowed_to calls this directly).
# ---------------------------------------------------------------------------
module Mngt
  module ProjectAllowedToMemberUnionPatch
    def allowed_to_member_union(user, permissions, entity_types: [])
      base_union = super(user, permissions, entity_types:)
      return base_union unless user.logged? && !user.anonymous?

      selects = entity_types.any? ? [arel_table[:id], Arel.sql("null AS entity_id")] : [arel_table[:id]]
      all_arel = unscoped.where("#{quoted_table_name}.active = TRUE").select(*selects).arel

      Arel::Nodes::UnionAll.new(base_union, all_arel)
    rescue StandardError => e
      Rails.logger.warn("[Mngt] allowed_to_member_union patch failed: #{e.message}")
      super(user, permissions, entity_types:)
    end
  end
end

# ---------------------------------------------------------------------------
# Patch 3: User#access_to? — used by Project#visible? instance method
# ---------------------------------------------------------------------------
module Mngt
  module UserAccessToPatch
    def access_to?(project)
      return project.active? if logged? && !anonymous?

      super
    end
  end
end

# ---------------------------------------------------------------------------
# Patch 4: UserPermissibleService — used by User#allowed_in_project?,
# User#allowed_in_work_package?, and controller before_action authorizations.
# Grants view permissions on all active projects to every logged-in user.
# ---------------------------------------------------------------------------
module Mngt
  module UserPermissibleServicePatch
    VIEW_PERMISSIONS = %i[
      view_project
      view_work_packages
      view_project_query
      view_own_time_entries
    ].freeze

    def allowed_in_single_project?(permissions, project)
      if user.logged? && !user.anonymous? && project&.active?
        requested = permissions.map { |p| p.name.to_sym }
        return true if (requested & VIEW_PERMISSIONS).any?
      end

      super
    end
  end
end

# ---------------------------------------------------------------------------
# Apply patches after all classes are loaded
# ---------------------------------------------------------------------------
Rails.application.config.after_initialize do
  Project.singleton_class.prepend(Mngt::ProjectVisiblePatch)
  Project.singleton_class.prepend(Mngt::ProjectAllowedToMemberUnionPatch)
  User.prepend(Mngt::UserAccessToPatch)
  Authorization::UserPermissibleService.prepend(Mngt::UserPermissibleServicePatch)
end
