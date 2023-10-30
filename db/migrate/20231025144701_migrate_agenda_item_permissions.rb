class MigrateAgendaItemPermissions < ActiveRecord::Migration[7.0]
  def change
    RolePermission.where(permission: 'create_meeting_agendas').update_all(permission: 'manage_agendas')
  end
end
