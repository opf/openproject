class RemoveOpenidEntirely < ActiveRecord::Migration
  def up
    drop_table 'open_id_authentication_nonces'
    drop_table 'open_id_authentication_associations'
  end

  def down
    create_table "open_id_authentication_associations", :force => true do |t|
      t.integer "issued"
      t.integer "lifetime"
      t.string  "handle"
      t.string  "assoc_type"
      t.binary  "server_url"
      t.binary  "secret"
    end

    create_table "open_id_authentication_nonces", :force => true do |t|
      t.integer "timestamp",  :null => false
      t.string  "server_url"
      t.string  "salt",       :null => false
    end
  end
end
