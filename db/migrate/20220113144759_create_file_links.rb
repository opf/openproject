class CreateFileLinks < ActiveRecord::Migration[6.1]
  def change
    create_table :file_links do |t|
      t.references :storage, foreign_key: true
      t.bigint :creator, null: false, foreign_key: true
      t.bigint :container, null: false, foreign_key: true
      t.string :container_type
      t.string :origin_id
      t.string :origin_name
      t.string :origin_mime_type
      t.timestamp :origin_created_at
      t.timestamp :origin_updated_at
      t.string :origin_last_modified_by_name

      t.timestamps
    end
  end
end
