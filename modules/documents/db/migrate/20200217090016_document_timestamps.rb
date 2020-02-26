class DocumentTimestamps < ActiveRecord::Migration[6.0]
  def change
    add_column :documents, :updated_at, :datetime
    rename_column :documents, :created_on, :created_at
    # We do not need the timestamp on the data table, as we already have it on the journals table.
    remove_column :document_journals, :created_on, :datetime

    reversible do |change|
      change.up { Document.update_all("updated_at = created_at") }
    end
  end
end
