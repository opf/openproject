class NonNullDataReferenceOnJournals < ActiveRecord::Migration[7.0]
  def change
    reversible do |direction|
      direction.up { execute "DELETE FROM journals WHERE data_id IS NULL or data_type IS NULL" }
    end

    change_column_null :journals, :data_id, false
    change_column_null :journals, :data_type, false
  end
end
