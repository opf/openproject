class AddForeignKeyConstraintForTypeColorId < ActiveRecord::Migration[7.0]
  def change
    # nullify invalid color references
    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE types
          SET color_id = NULL
          WHERE types.color_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM colors
              WHERE colors.id = types.color_id
            )
        SQL
      end
    end

    add_foreign_key :types, :colors, on_delete: :nullify
  end
end
