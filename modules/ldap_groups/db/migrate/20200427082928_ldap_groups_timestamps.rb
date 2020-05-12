class LdapGroupsTimestamps < ActiveRecord::Migration[6.0]
  def up
    change_column_default :ldap_groups_synchronized_groups, :created_at, -> { 'CURRENT_TIMESTAMP' }
    change_column_default :ldap_groups_synchronized_groups, :updated_at, -> { 'CURRENT_TIMESTAMP' }

    change_column_default :ldap_groups_synchronized_filters, :created_at, -> { 'CURRENT_TIMESTAMP' }
    change_column_default :ldap_groups_synchronized_filters, :updated_at, -> { 'CURRENT_TIMESTAMP' }

    change_column_default :ldap_groups_memberships, :created_at, -> { 'CURRENT_TIMESTAMP' }
    change_column_default :ldap_groups_memberships, :updated_at, -> { 'CURRENT_TIMESTAMP' }
  end

  def down
    # Nothing to do
  end
end
