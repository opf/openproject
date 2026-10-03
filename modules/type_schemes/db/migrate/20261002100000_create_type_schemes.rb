class CreateTypeSchemes < ActiveRecord::Migration[8.1]
  def change
    create_table :type_schemes do |t|
      t.string  :name, null: false, index: { unique: true }
      t.text    :description
      t.boolean :is_default, null: false, default: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :type_schemes, :is_default, unique: true, where: "is_default", name: "idx_type_scheme_one_default"

    create_table :type_scheme_items do |t|
      t.references :scheme, null: false, foreign_key: { to_table: :type_schemes, on_delete: :cascade }
      t.references :type,   null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false, default: 0
      t.boolean :is_default, null: false, default: false
      t.timestamps
      t.index %i[scheme_id type_id], unique: true
      t.index :scheme_id, unique: true, where: "is_default", name: "idx_type_scheme_item_one_default"
    end

    create_table :project_type_schemes do |t|
      t.references :project, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.references :scheme,  null: false, foreign_key: { to_table: :type_schemes }
      t.timestamps
    end
  end
end
