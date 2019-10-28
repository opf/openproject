class SimplifyProjectActiveAndTimestamp < ActiveRecord::Migration[6.0]
  STATUS_ACTIVE     = 1
  STATUS_ARCHIVED   = 9

  class Project < ActiveRecord::Base; end

  def change
    change_project_columns

    reversible do |change|
      change.up do
        fill_active_column
      end
      change.down do
        recreate_status_column_and_information
      end
    end
  end

  private

  def change_project_columns
    change_table :projects do |table|
      table.rename :created_on, :created_at
      table.rename :updated_on, :updated_at
      table.rename :is_public, :public
    end
  end

  def fill_active_column
    add_column :projects, :active, :boolean, default: true, index: true, null: false

    Project.reset_column_information
    Project.where(status: STATUS_ARCHIVED).update_all(active: false)

    remove_column :projects, :status
  end

  def recreate_status_column_and_information
    add_column :projects, :status, :integer, default: STATUS_ACTIVE, null: false

    Project.reset_column_information
    Project.where(active: true).update_all(status: STATUS_ACTIVE)
    Project.where(active: false).update_all(status: STATUS_ARCHIVED)

    remove_column :projects, :active
  end
end
