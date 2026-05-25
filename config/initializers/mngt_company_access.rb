# frozen_string_literal: true

# Company-wide access for project hierarchies.
#
# Members of a company root project (tracked via mngt_project_api_ids with no
# api_area_id / api_sector_id) automatically get full access to every descendant
# project, without needing an explicit Member record in those sub-projects.
#
# Effects:
#   - Descendants appear in project listings for company members
#   - All permission checks (view, edit, create WPs, etc.) pass for company members
#   - Work packages in those projects are visible to company members
#   - Users do NOT appear in member lists or assignee pickers of projects where
#     they are not explicit members — only their own path is shown.
#
# This is purely additive: projects not tracked in mngt_project_api_ids are
# completely unaffected.

module Mngt
  module CompanyAccess
    TABLE_CHECK_QUERY = <<~SQL.freeze
      SELECT 1 FROM information_schema.tables
      WHERE table_name = 'mngt_project_api_ids' LIMIT 1
    SQL

    def self.available?
      @available ||= ActiveRecord::Base.connection.select_value(TABLE_CHECK_QUERY).present?
    rescue StandardError
      false
    end

    # SQL subquery returning IDs of descendant projects reachable via company
    # root membership for the given user. Optionally filtered to permissions and
    # enabled module names so it can be used inside any allowed_to query.
    def self.descendant_sql(user_id, permissions: nil, modules: nil)
      conn = ActiveRecord::Base.connection
      p_q  = Project.quoted_table_name

      sql = <<~SQL
        SELECT p.id
        FROM #{p_q} p
        INNER JOIN #{p_q} root_p
          ON root_p.lft < p.lft
         AND root_p.rgt > p.rgt
         AND root_p.active = TRUE
        INNER JOIN mngt_project_api_ids api
          ON api.project_id = root_p.id
         AND api.api_area_id IS NULL
         AND api.api_sector_id IS NULL
        INNER JOIN #{Member.quoted_table_name} m
          ON m.project_id = root_p.id
         AND m.user_id = #{user_id.to_i}
         AND m.entity_type IS NULL
        INNER JOIN #{MemberRole.quoted_table_name} mr
          ON mr.member_id = m.id
         AND mr.inherited_from IS NULL
      SQL

      if permissions.present?
        perm_list = permissions.map { |p| conn.quote(p.name.to_s) }.join(", ")
        sql += <<~SQL
          INNER JOIN #{RolePermission.quoted_table_name} rp
            ON rp.role_id = mr.role_id
           AND rp.permission IN (#{perm_list})
        SQL
      end

      if modules.present?
        mod_list = modules.map { |mod| conn.quote(mod.to_s) }.join(", ")
        sql += <<~SQL
          INNER JOIN #{EnabledModule.quoted_table_name} em
            ON em.project_id = p.id
           AND em.name IN (#{mod_list})
        SQL
      end

      sql + "WHERE p.active = TRUE"
    end

    # Returns true when the project is a descendant of a company root where
    # the user has explicit membership. Used for individual visibility checks.
    def self.accessible?(user, project)
      return false unless user.logged? && available?

      sql = "SELECT 1 FROM (#{descendant_sql(user.id)}) sub WHERE sub.id = #{project.id.to_i} LIMIT 1"
      ActiveRecord::Base.connection.select_value(sql).present?
    rescue StandardError => e
      Rails.logger.warn("[Mngt::CompanyAccess] accessible? failed: #{e.message}")
      false
    end
  end
end

# ---------------------------------------------------------------------------
# Patch 1: Project.visible — project listing / navigation
# ---------------------------------------------------------------------------
module Mngt
  module ProjectVisiblePatch
    def visible(user = User.current)
      base = super(user)
      return base if !user.logged? || user.active_admin? || user.anonymous?
      return base unless Mngt::CompanyAccess.available?

      sql = Mngt::CompanyAccess.descendant_sql(user.id)
      base.or(active.where("#{quoted_table_name}.id IN (#{sql})"))
    rescue StandardError => e
      Rails.logger.warn("[Mngt::CompanyAccess] Project.visible patch failed: #{e.message}")
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
      return base_union if !user.logged? || user.active_admin?
      return base_union unless Mngt::CompanyAccess.available?

      project_modules = permissions.filter_map(&:project_module).uniq
      sql = Mngt::CompanyAccess.descendant_sql(
        user.id,
        permissions: permissions,
        modules:     project_modules.presence
      )

      selects = entity_types.any? ? [arel_table[:id], Arel.sql("null AS entity_id")] : [arel_table[:id]]

      company_arel = unscoped.active
                             .where("#{quoted_table_name}.id IN (#{sql})")
                             .select(*selects)
                             .arel

      Arel::Nodes::UnionAll.new(base_union, company_arel)
    rescue StandardError => e
      Rails.logger.warn("[Mngt::CompanyAccess] allowed_to_member_union patch failed: #{e.message}")
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
      super || Mngt::CompanyAccess.accessible?(self, project)
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
end
