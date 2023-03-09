class UniqueIndexOnCustomFieldsProjects < ActiveRecord::Migration[7.0]
  def change
    reversible do |direction|
      direction.up { remove_duplicates }
    end

    remove_index :custom_fields_projects,
                 %i[custom_field_id project_id]

    add_index :custom_fields_projects,
              %i[custom_field_id project_id],
              unique: true
  end

  private

  # Selects all distinct tuples of (project_id, custom_field_id), then removes the whole content
  # of custom_fields_projects to then add the distinct tuples again.
  def remove_duplicates
    execute <<~SQL.squish
      WITH selection AS (
        SELECT
          project_id,
          custom_field_id
        FROM
          custom_fields_projects
        GROUP BY
          (project_id, custom_field_id)
      ),
      deletion AS (
        DELETE FROM
          custom_fields_projects
      ),
      insertion AS (
        INSERT INTO
          custom_fields_projects
        SELECT
          project_id,
          custom_field_id
        FROM
          selection
      )

      SELECT 1
    SQL
  end
end
