class MoveBaseDnIntoFilters < ActiveRecord::Migration[6.1]
  def change
    add_column :ldap_groups_synchronized_filters, :base_dn, :text, null: true

    # Add sync_users option to filters
    add_column :ldap_groups_synchronized_filters,
               :sync_users,
               :boolean,
               null: false,
               default: false

    # Add sync_users option to groups
    add_column :ldap_groups_synchronized_groups,
               :sync_users,
               :boolean,
               null: false,
               default: false


    LdapGroups::SynchronizedFilter.reset_column_information
    LdapGroups::SynchronizedGroup.reset_column_information

    # Take over the connection's onthefly setting
    # for whether to sync users for filters and groups
    LdapAuthSource
      .pluck(:id, :onthefly_register)
      .each do |id, onthefly|
      LdapGroups::SynchronizedFilter
        .where(auth_source_id: id)
        .update_all(sync_users: onthefly)

      LdapGroups::SynchronizedGroup
        .where(auth_source_id: id)
        .update_all(sync_users: onthefly)
    end
  end
end
