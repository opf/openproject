class CreateNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :notifications do |t|
      t.text :subject
      t.boolean :read_ian, default: false, index: true
      t.boolean :read_email, default: false, index: true
      t.integer :reason, limit: 1

      t.references :recipient, null: false, index: true, foreign_key: { to_table: :users }
      t.references :actor, null: true, foreign_key: { to_table: :users }

      t.references :resource, polymorphic: true, null: false
      t.references :project
      t.references :journal, index: false

      t.timestamps
    end
  end
end
