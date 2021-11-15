class AddGroupUserPrimaryKey < ActiveRecord::Migration[6.1]
  def change
    # Adding a primary key will automatically fill that column with values.
    # Therefore, there is no need to assign it manually.
    add_column :group_users, :id, :primary_key

    add_index :group_users, %i[user_id group_id], unique: true
  end
end
