class AddUserIdToSessions < ActiveRecord::Migration[5.0]
  def change
    add_column :sessions, :user_id, :integer, index: true
  end
end
