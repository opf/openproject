class AddCustomFieldJournal < ActiveRecord::Migration
  def change
    create_table :customizable_journals, id: false do |t|
      t.integer :journal_id, null: false
      t.integer :custom_field_id, null: false
      t.string  :value, :default_value
    end

    add_index :customizable_journals, :journal_id
    add_index :customizable_journals, [:journal_id, :custom_field_id], unique: true
  end
end
