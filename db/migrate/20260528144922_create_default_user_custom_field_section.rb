# frozen_string_literal: true

class CreateDefaultUserCustomFieldSection < ActiveRecord::Migration[8.1]
  def up
    section_id = execute(<<~SQL.squish).first["id"]
      INSERT INTO custom_field_sections (type, name, position, created_at, updated_at)
      VALUES ('UserCustomFieldSection', NULL, 1, NOW(), NOW())
      RETURNING id
    SQL

    execute(<<~SQL.squish)
      UPDATE custom_fields
      SET custom_field_section_id = #{section_id}
      WHERE type = 'UserCustomField'
        AND custom_field_section_id IS NULL
    SQL
  end

  def down
    execute(<<~SQL.squish)
      UPDATE custom_fields
      SET custom_field_section_id = NULL
      WHERE type = 'UserCustomField'
        AND custom_field_section_id IN (
          SELECT id FROM custom_field_sections
          WHERE type = 'UserCustomFieldSection' AND name IS NULL
        )
    SQL

    execute(<<~SQL.squish)
      DELETE FROM custom_field_sections
      WHERE type = 'UserCustomFieldSection' AND name IS NULL
    SQL
  end
end
