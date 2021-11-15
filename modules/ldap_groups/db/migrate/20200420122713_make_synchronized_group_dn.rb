class MakeSynchronizedGroupDn < ActiveRecord::Migration[6.0]
  def up
    add_column :ldap_groups_synchronized_groups, :dn, :text, index: true
    add_column :ldap_groups_synchronized_groups,
               :users_count,
               :integer,
               default: 0,
               null: false

    LdapGroups::SynchronizedGroup.find_each do |group|
      dn = ::OpenProject::LdapGroups.group_dn(Net::LDAP::DN.escape(group.entry))
      group.update_column(:dn, dn)
    end

    remove_column :ldap_groups_synchronized_groups, :entry, :text
  end

  def down
    add_column :ldap_groups_synchronized_groups, :entry, :text

    warn "Removing synchronized groups"
    LdapGroups::SynchronizedGroup.destroy_all

    remove_column :ldap_groups_synchronized_groups, :dn
    remove_column :ldap_groups_synchronized_groups, :users_count
  end
end
