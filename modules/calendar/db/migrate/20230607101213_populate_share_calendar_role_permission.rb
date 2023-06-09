require Rails.root.join("db/migrate/migration_utils/permission_adder")

class PopulateShareCalendarRolePermission < ActiveRecord::Migration[7.0]
  def up
    # From https://community.openproject.org/projects/openproject/work_packages/15339/activity
    # -> For the migration path, all the roles that has the setting "View calendars" active will
    # also by default have "Subscribe to iCalendars" active
    ::Migration::MigrationUtils::PermissionAdder
      .add(:view_calendar,
           :share_calendars)
  end

  def down
    # nothing to do
  end
end
