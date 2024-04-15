class ICalTokenQueryAssignment < ActiveRecord::Migration[7.0]
  def change
    create_table :ical_token_query_assignments do |t|
      t.references :ical_token, foreign_key: { to_table: :tokens, on_delete: :cascade }
      t.references :query, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end
