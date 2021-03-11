class MakeSystemUserActive < ActiveRecord::Migration[6.0]
  # Remember the integer mapped to previous builtin status
  BUILTIN_STATUS ||= 0

  def up
    Principal.where(status: BUILTIN_STATUS).update_all(status: Principal.statuses[:active])
  end

  def down
    AnonymousUser.update_all(status: BUILTIN_STATUS)
    DeletedUser.update_all(status: BUILTIN_STATUS)
    SystemUser.update_all(status: Principal.statuses[:locked])
  end
end
