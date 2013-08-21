class AddAttachableJournal < ActiveRecord::Migration
  def change
    create_table :attachable_journals do |t|
      t.integer :journal_id, null: false
      t.integer :attachment_id, null: false
      t.string  :filename, :default => '', :null => false
    end

    add_index :attachable_journals, :journal_id
    add_index :attachable_journals, :attachment_id
  end
end
