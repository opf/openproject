class RenameColumnsOnProjectQueries < ActiveRecord::Migration[7.1]
  def change
    rename_column :project_queries, :columns, :selects
  end
end
