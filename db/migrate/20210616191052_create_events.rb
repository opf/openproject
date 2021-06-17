class CreateEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :events do |t|
      t.text :subject
      t.boolean :read_ian, default: false, index: true
      t.boolean :read_email, default: false, index: true
      t.integer :reason, limit: 1
      t.references :recipient, null: false, index: true, foreign_key: { to_table: :users }
      t.references :context, polymorphic: true, null: false
      t.references :resource, polymorphic: true, null: false

      t.timestamps
    end
  end
end
