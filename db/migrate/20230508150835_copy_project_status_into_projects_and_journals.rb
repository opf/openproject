class CopyProjectStatusIntoProjectsAndJournals < ActiveRecord::Migration[7.0]
  def change
    add_status_columns_to_projects
    add_status_columns_to_project_journals

    reversible do |dir|
      dir.up do
        copy_project_status_into_projects
        copy_project_status_into_journals
      end

      dir.down do
        clear_status_from_project_journals
        restore_project_statuses
      end
    end

    drop_project_statuses_table
  end

  private

  def add_status_columns_to_projects
    change_table :projects, bulk: true do |table|
      table.integer :status_code
      table.text :status_explanation
    end
  end

  def add_status_columns_to_project_journals
    change_table :project_journals, bulk: true do |table|
      table.integer :status_code
      table.text :status_explanation
    end
  end

  def copy_project_status_into_projects
    execute <<~SQL.squish
      UPDATE projects
      SET status_code = project_statuses.code,
          status_explanation = project_statuses.explanation
      FROM project_statuses
      WHERE project_statuses.project_id = projects.id
    SQL
  end

  def copy_project_status_into_journals
    execute <<~SQL.squish
      UPDATE project_journals
      SET status_code = projects.status_code,
          status_explanation = projects.status_explanation
      FROM projects
      JOIN journals ON journals.journable_id = projects.id
      AND journals.journable_type = 'Project'
      WHERE project_journals.id = journals.data_id
        AND journals.data_type = 'Journal::ProjectJournal'
    SQL
  end

  def clear_status_from_project_journals
    execute <<~SQL.squish
      UPDATE project_journals
      SET status_code = NULL,
          status_explanation = NULL
    SQL
  end

  def restore_project_statuses
    execute <<~SQL.squish
      INSERT INTO project_statuses (
        project_id,
        code,
        explanation,
        created_at,
        updated_at
      )
      SELECT id,
             status_code,
             status_explanation,
             created_at,
             updated_at
      FROM projects
      WHERE projects.status_code IS NOT NULL
         OR projects.status_explanation IS NOT NULL
    SQL
  end

  def drop_project_statuses_table
    drop_table :project_statuses do |table|
      table.references :project, null: false, foreign_key: true, index: { unique: true }
      table.text :explanation
      table.integer :code
      table.timestamps
    end
  end
end
