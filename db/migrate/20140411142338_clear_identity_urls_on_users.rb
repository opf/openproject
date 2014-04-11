class ClearIdentityUrlsOnUsers < ActiveRecord::Migration
  def up
    create_table "legacy_user_identity_urls" do |t|
      t.string   "login", :limit => 256, :default => "",    :null => false
      t.string   "identity_url"
    end

    execute "INSERT INTO legacy_user_identity_urls(id, login, identity_url)
             SELECT id, login, identity_url FROM users"

    execute "UPDATE users SET identity_url = NULL"
  end

  def down
    if mysql?

      execute "UPDATE users u
               JOIN legacy_user_identity_urls lu ON u.id = lu.id
               SET u.identity_url = lu.identity_url"

    elsif postgres?

      execute "UPDATE users
               SET identity_url = lu.identity_url
               FROM legacy_user_identity_urls lu
               WHERE users.id = lu.id"

    else
      raise "The down part of this migration only supports MySQL and PostgreSQL."
    end

    drop_table :legacy_user_identity_urls
  end

  def postgres?
    ActiveRecord::Base.connection.instance_values["config"][:adapter] == "postgresql"
  end

  def mysql?
    ActiveRecord::Base.connection.instance_values["config"][:adapter] == "mysql2"
  end
end
