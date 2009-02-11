# Use this migration to upgrade the old 1.1 ActiveRecord store schema
# to the new 2.0 schema.
class UpgradeOpenIdStore < ActiveRecord::Migration
  def self.up
    drop_table "open_id_settings"
    drop_table "open_id_nonces"
    create_table "open_id_nonces", :force => true do |t|
      t.column :server_url, :string, :null => false
      t.column :timestamp, :integer, :null => false
      t.column :salt, :string, :null => false
    end
  end

  def self.down
    drop_table "open_id_nonces"
    create_table "open_id_nonces", :force => true do |t|
      t.column "nonce", :string
      t.column "created", :integer
    end

    create_table "open_id_settings", :force => true do |t|
      t.column "setting", :string
      t.column "value", :binary
    end
  end
end
