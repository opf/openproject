class RemoveInvalidGroupUsers < ActiveRecord::Migration[6.1]
  def up
    GroupUser.left_outer_joins(:user).where(users: { id: nil }).destroy_all
  end
end
