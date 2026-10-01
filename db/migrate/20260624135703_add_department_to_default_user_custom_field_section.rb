# frozen_string_literal: true

class AddDepartmentToDefaultUserCustomFieldSection < ActiveRecord::Migration[8.1]
  # Append the new built-in `department` attribute to the default section (the
  # first UserCustomFieldSection by position) where the other built-ins already
  # live. Idempotent: skips sections that already contain the key.
  def up
    execute(<<~SQL.squish)
      UPDATE custom_field_sections
      SET attribute_order = array_append(attribute_order, 'department')
      WHERE id = (
        SELECT id FROM custom_field_sections
        WHERE type = 'UserCustomFieldSection'
        ORDER BY position
        LIMIT 1
      )
      AND NOT ('department' = ANY(attribute_order))
    SQL
  end

  def down
    execute(<<~SQL.squish)
      UPDATE custom_field_sections
      SET attribute_order = array_remove(attribute_order, 'department')
      WHERE type = 'UserCustomFieldSection'
    SQL
  end
end
