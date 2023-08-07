class RenameAuthSourceToLdapAuthSource < ActiveRecord::Migration[7.0]
  def change
    rename_table :auth_sources, :ldap_auth_sources
    rename_column :users, :auth_source_id, :ldap_auth_source_id
    rename_column :ldap_groups_synchronized_groups, :auth_source_id, :ldap_auth_source_id
    rename_column :ldap_groups_synchronized_filters, :auth_source_id, :ldap_auth_source_id
  end
end
