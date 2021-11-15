class AddTlsModeToAuthSources < ActiveRecord::Migration[5.2]
  def change
    add_column :auth_sources, :tls_mode, :integer, default: 0, null: false
    LdapAuthSource.reset_column_information

    reversible do |dir|
      dir.up do
        LdapAuthSource.where(tls: true).update_all(tls_mode: 1)
      end

      dir.down do
        LdapAuthSource.where(tls_mode: 0).update_all(tls: false)
        LdapAuthSource.where(tls_mode: 1).update_all(tls: true)
      end
    end

    remove_column :auth_sources, :tls, :boolean, default: false, null: false
  end
end
