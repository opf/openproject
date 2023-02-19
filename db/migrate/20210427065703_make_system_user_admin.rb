class MakeSystemUserAdmin < ActiveRecord::Migration[6.1]
  def up
    User.system.update_column(:admin, true)
  end

  def down
    User.system.update_column(:admin, false)
  end
end
