class NonNullDataReferenceOnJournals < ActiveRecord::Migration[7.0]
  def change
    change_column_null :journals, :data_id, false
    change_column_null :journals, :data_type, false
  end
end
