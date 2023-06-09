class PopulateShareCalendarRolePermission < ActiveRecord::Migration[7.0]
  def up
    # From https://community.openproject.org/projects/openproject/work_packages/15339/activity
    # -> For the migration path, all the roles that has the setting "View calendars" active will
    # also by default have "Subscribe to iCalendars" active
    role_ids_with_view_calendar_permission = RolePermission.where(permission: "view_calendar").distinct(:role_id).pluck(:role_id)

    new_permissions = role_ids_with_view_calendar_permission.map do |role_id|
      { role_id:, permission: "share_calendars" }
    end

    RolePermission.insert_all(new_permissions) unless new_permissions.empty?
  end

  def down
    # Question: is following down migration desired? I tend to not include that as it (in theory) might
    # remove manually set share_calendar permissions
    # RolePermission.where(permission: "share_calendars").delete_all
  end
end
