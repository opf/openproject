class NonNullDataReferenceOnJournals < ActiveRecord::Migration[7.0]
  def change
    reversible do |direction|
      direction.up do
        change_on_delete_on_notification_fk(true)
        cleanup_invalid_journals
      end
      direction.down do
        change_on_delete_on_notification_fk(false)
      end
    end

    change_non_null_data_columns
  end

  private

  def change_non_null_data_columns
    change_column_null :journals, :data_id, false
    change_column_null :journals, :data_type, false
  end

  def cleanup_invalid_journals
    execute <<~SQL.squish
      DELETE FROM journals
      WHERE data_id IS NULL OR data_type IS NULL
    SQL
  end

  def change_on_delete_on_notification_fk(cascade)
    options = if cascade
                { on_delete: :cascade }
              else
                {}
              end

    remove_foreign_key :notifications, :journals

    add_foreign_key :notifications,
                    :journals,
                    **options
  end
end
