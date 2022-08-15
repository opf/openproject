class CreateFileLinks < ActiveRecord::Migration[6.1]
  def change
    create_table :file_links do |t|
      t.references :storage, foreign_key: { on_delete: :cascade }
      t.references :creator,
                   null: false,
                   index: true,
                   foreign_key: { to_table: :users }
      t.bigint :container_id, null: false
      t.string :container_type, null: false

      t.string :origin_id
      t.string :origin_name
      t.string :origin_created_by_name
      t.string :origin_last_modified_by_name
      t.string :origin_mime_type
      t.timestamp :origin_created_at
      t.timestamp :origin_updated_at

      t.timestamps

      # i.e. show all file links per WP.
      t.index %i[container_id container_type]
      # i.e. show all work packages per file.
      t.index %i[origin_id storage_id]
    end
  end
end
