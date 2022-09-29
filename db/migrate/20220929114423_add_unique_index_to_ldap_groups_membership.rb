class AddUniqueIndexToLdapGroupsMembership < ActiveRecord::Migration[7.0]
  def change
    add_index :ldap_groups_memberships, %i[user_id group_id], unique: true
  end
end
