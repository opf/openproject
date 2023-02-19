class AddLdapTlsOptions < ActiveRecord::Migration[7.0]
  def change
    change_table :auth_sources, bulk: true do |t|
      t.boolean :verify_peer, default: true, null: false
      t.text :tls_certificate_string
    end

    reversible do |dir|
      dir.up do
        # Current LDAP library default is to not verify the certificate
        LdapAuthSource.reset_column_information
        ldap_settings = (Setting.ldap_tls_options || {}).with_indifferent_access
        verify_peer = ldap_settings[:verify_mode] == OpenSSL::SSL::VERIFY_PEER
        LdapAuthSource.update_all(verify_peer:)
      end
    end
  end
end
