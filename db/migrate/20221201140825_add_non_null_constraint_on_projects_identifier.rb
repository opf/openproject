class AddNonNullConstraintOnProjectsIdentifier < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up do
        # should not be needed as all identifiers should be present
        execute <<~SQL.squish
          UPDATE projects
          SET identifier = 'project-' || id
          WHERE identifier IS NULL
        SQL
      end
    end

    change_column_null :projects, :identifier, false
  end
end
