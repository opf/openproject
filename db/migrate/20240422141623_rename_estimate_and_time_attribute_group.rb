class RenameEstimateAndTimeAttributeGroup < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL.squish
      UPDATE types
      SET attribute_groups = REPLACE(attribute_groups, '- - :estimates_and_time', '- - :estimates_and_progress')
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE types
      SET attribute_groups = REPLACE(attribute_groups, '- - :estimates_and_progress', '- - :estimates_and_time')
    SQL
  end
end
