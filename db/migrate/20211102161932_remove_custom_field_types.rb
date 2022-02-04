class RemoveCustomFieldTypes < ActiveRecord::Migration[6.1]
  def up
    delete_custom_field('TimeEntryActivityCustomField')
    delete_custom_field('DocumentCategoryCustomField')
    delete_custom_field('IssuePriorityCustomField')

    delete_custom_values
  end

  def delete_custom_field(type)
    execute <<~SQL.squish
      DELETE FROM
        custom_fields
      WHERE
        type = '#{type}'
    SQL
  end

  def delete_custom_values
    execute <<~SQL.squish
      DELETE FROM
        custom_values values_delete
      USING
        custom_values values_select
      LEFT OUTER JOIN
        custom_fields
      ON
        custom_fields.id = values_select.custom_field_id
      WHERE
        values_delete.id = values_select.id
      AND
        custom_fields.id IS NULL
    SQL
  end
end
