class AddSynchronizedFilters < ActiveRecord::Migration[6.0]
  def change
    create_table :ldap_groups_synchronized_filters do |t|
      t.string :name
      t.string :group_name_attribute
      t.string :filter_string
      t.references :auth_source

      t.timestamps
    end

    change_table :ldap_groups_synchronized_groups do |t|
      t.belongs_to :filter, foreign_key: { to_table: :ldap_groups_synchronized_filters }
    end
  end
end
