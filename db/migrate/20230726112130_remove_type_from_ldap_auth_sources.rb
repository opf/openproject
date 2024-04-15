class RemoveTypeFromLdapAuthSources < ActiveRecord::Migration[7.0]
  def change
    remove_column :ldap_auth_sources, :type, :string, null: false
  end
end
