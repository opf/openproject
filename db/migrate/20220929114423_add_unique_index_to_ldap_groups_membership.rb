class AddUniqueIndexToLdapGroupsMembership < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up { remove_duplicate_memberships! }
    end

    add_index :ldap_groups_memberships, %i[user_id group_id], unique: true
  end

  def remove_duplicate_memberships!
    ActiveRecord::Base.connection.execute <<~SQL.squish
      DELETE FROM ldap_groups_memberships m1
      USING ldap_groups_memberships m2
      WHERE m1.id < m2.id AND m1.user_id = m2.user_id AND m1.group_id = m2.group_id;
    SQL
  end
end
