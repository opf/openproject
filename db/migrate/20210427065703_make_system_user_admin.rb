class MakeSystemUserAdmin < ActiveRecord::Migration[6.1]
  def up
    User.system.update_attribute(:admin, true)
  end

  def down
    User.system.update_attribute(:admin, false)
  end
end
