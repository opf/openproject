class RemoveEnums < ActiveRecord::Migration[7.1]
  def up
    change_column(:storages, :health_status, :string, default: "pending")
    add_check_constraint(:storages,
                         "health_status IN ('pending', 'healthy', 'unhealthy')",
                         name: "storages_health_status_check")

    change_column(:last_project_folders, :mode, :string, default: "inactive")
    add_check_constraint(:last_project_folders,
                         "mode IN ('inactive', 'manual', 'automatic')",
                         name: "last_project_folders_mode_check")

    change_column(:project_storages, :project_folder_mode, :string)
    add_check_constraint(:project_storages,
                         "project_folder_mode IN ('inactive', 'manual', 'automatic')",
                         name: "project_storages_project_folder_mode_check")

    change_column(:delayed_job_statuses, :status, :string, default: "in_queue")
    add_check_constraint(:delayed_job_statuses,
                         "status IS NULL OR status IN ('in_queue', 'error', 'in_process', 'success', 'failure', 'cancelled')",
                         name: "delayed_job_statuses_status_check")

    execute <<~SQL.squish
      DROP TYPE delayed_job_status RESTRICT;
      DROP TYPE project_folder_modes RESTRICT;
      DROP TYPE storage_health_statuses RESTRICT;
    SQL
  end

  def down
    execute <<~SQL.squish
      CREATE TYPE delayed_job_status AS ENUM (
          'in_queue',
          'error',
          'in_process',
          'success',
          'failure',
          'cancelled'
      );

      CREATE TYPE project_folder_modes AS ENUM (
          'inactive',
          'manual',
          'automatic'
      );

      CREATE TYPE storage_health_statuses AS ENUM (
          'pending',
          'healthy',
          'unhealthy'
      );
    SQL

    remove_check_constraint(:storages, name: "storages_health_status_check")
    change_column(:storages, :health_status, :storage_health_statuses, default: nil,
                                                                       using: "health_status::storage_health_statuses")

    remove_check_constraint(:last_project_folders, name: "last_project_folders_mode_check")

    change_column_default(:storages, :health_status, "pending")

    change_column(:last_project_folders, :mode, :project_folder_modes, default: nil, using: "mode::project_folder_modes")
    change_column_default(:last_project_folders, :mode, "inactive")

    remove_check_constraint(:project_storages, name: "project_storages_project_folder_mode_check")
    change_column(:project_storages, :project_folder_mode, :project_folder_modes, default: nil,
                                                                                  using: "project_folder_mode::project_folder_modes")

    remove_check_constraint(:delayed_job_statuses, name: "delayed_job_statuses_status_check")
    change_column(:delayed_job_statuses, :status, :delayed_job_status, default: nil, using: "status::delayed_job_status")
    change_column_default(:delayed_job_statuses, :status, "in_queue")
  end
end
