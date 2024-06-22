class RenameColumnsOnProjectQueries < ActiveRecord::Migration[7.1]
  def change
    rename_column :project_queries, :columns, :selects

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE project_queries
          SET selects = '#{Setting.enabled_projects_columns}'
        SQL
      end

      dir.down do
        execute <<~SQL.squish
          UPDATE project_queries
          SET selects = '[]'
        SQL
      end
    end
  end
end
