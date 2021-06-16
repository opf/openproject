class CreateEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :events do |t|
      t.text :subject
      t.boolean :read_iam
      t.boolean :read_email
      t.integer :reason, limit: 1
      t.references :recipient, index: true, foreign_key: { to_table: :users }
      t.references :context, polymorphic: true
      t.references :resource, polymorphic: true

      t.timestamps
    end
  end
end
