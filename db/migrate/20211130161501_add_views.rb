class AddViews < ActiveRecord::Migration[6.1]
  def change
    create_table :views do |t|
      t.references :query, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :options, default: {}, null: false
      t.string :type, null: false

      t.timestamps
    end
  end
end
