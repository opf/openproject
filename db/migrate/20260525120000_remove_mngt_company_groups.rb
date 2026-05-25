# frozen_string_literal: true

# Removes company-level groups that were created by the old UserSyncService
# (one group per company, added as member to all company projects).
#
# These groups are identified by their lastname matching a company root project
# name (a project tracked in mngt_project_api_ids with no api_area_id / api_sector_id).
#
# Cleanup sequence:
#   1. Destroy group Member records  → cascades to their MemberRole records
#   2. SQL: delete orphaned inherited MemberRoles whose parent MemberRole is gone
#   3. Remove Member records that now have no roles (users left empty by step 2)
#   4. Destroy the group principals

class RemoveMngtCompanyGroups < ActiveRecord::Migration[7.1]
  def up
    company_group_ids = find_company_group_ids
    return say "No company groups found — skipping." if company_group_ids.empty?

    say "Found #{company_group_ids.size} company group(s): #{company_group_ids.inspect}"

    # Step 1: remove group memberships in all projects (cascades to group's MemberRoles)
    group_member_ids = Member.where(user_id: company_group_ids).pluck(:id)
    say "  Removing #{group_member_ids.size} group Member record(s)..."
    Member.where(id: group_member_ids).destroy_all

    # Step 2: clean up inherited MemberRoles whose parent no longer exists
    say "  Cleaning up orphaned inherited MemberRoles..."
    deleted_member_ids = execute_cleanup_sql

    # Step 3: remove Member records that now have no roles at all
    say "  Removing empty Member records..."
    empty_member_ids = Member
      .where(id: deleted_member_ids)
      .where.not(id: MemberRole.select(:member_id).distinct)
      .pluck(:id)
    Member.where(id: empty_member_ids).destroy_all
    say "  Removed #{empty_member_ids.size} empty Member record(s)."

    # Step 4: delete the group principals directly (skip the async DeleteService)
    say "  Deleting #{company_group_ids.size} group principal(s)..."
    GroupUser.where(group_id: company_group_ids).delete_all
    execute("DELETE FROM group_details WHERE principal_id IN (#{company_group_ids.join(', ')})")
    Principal.where(id: company_group_ids).delete_all

    say "Done. Company groups removed."
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "Cannot restore auto-generated company groups. Re-run Mngt::UserSyncService.sync_all if needed."
  end

  private

  def find_company_group_ids
    return [] unless table_exists?(:mngt_project_api_ids)

    company_project_names = Project
      .joins("INNER JOIN mngt_project_api_ids api ON api.project_id = projects.id")
      .where("api.api_area_id IS NULL AND api.api_sector_id IS NULL")
      .pluck(:name)

    return [] if company_project_names.empty?

    Group.where(lastname: company_project_names).pluck(:id)
  end

  def execute_cleanup_sql
    result = execute(<<~SQL)
      DELETE FROM member_roles
      USING member_roles orphaned
      WHERE
        orphaned.id = member_roles.id
        AND orphaned.inherited_from IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM member_roles parent
          WHERE parent.id = orphaned.inherited_from
        )
      RETURNING member_roles.member_id
    SQL

    result.column_values(0).uniq
  end
end
