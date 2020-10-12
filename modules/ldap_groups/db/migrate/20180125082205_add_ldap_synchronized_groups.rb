class AddLdapSynchronizedGroups < ActiveRecord::Migration[5.0]
  def change
    create_table :ldap_groups_synchronized_groups do |t|
      t.string :entry
      t.references :group
      t.references :auth_source

      t.timestamps
    end

    create_table :ldap_groups_memberships do |t|
      t.references :user
      t.references :group

      t.timestamps
    end
  end
end
