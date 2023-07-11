class AddCauseToJournal < ActiveRecord::Migration[7.0]
  def change
    add_column :journals, :cause, :jsonb, default: {}
  end
end
