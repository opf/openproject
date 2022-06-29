class AddPaperTrail < ActiveRecord::Migration[7.0]
  def change
    create_table :paper_trail_audits do |t|
      t.string :item_type, null: false
      t.bigint :item_id, null: false
      t.string :event, null: false
      t.string :whodunnit
      t.text :stack
      t.jsonb :object
      t.jsonb :object_changes

      t.datetime :created_at
    end
    add_index :paper_trail_audits, %i(item_type item_id)
  end
end
