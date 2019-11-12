class FixSystemUserStatus < ActiveRecord::Migration[6.0]
  def up
    # The previous migration was supposed to make the system user active,
    # but doesn't since it only touches built-in (0) users while the system user
    # used to be locked (3). An oversight on our part.
    #
    # We also update the anonymous user again. While it was correctly updated
    # in the previous migration, newly created anonymous users since have the
    # wrong status (0) because we failed to update the on-the-fly
    # creation of the anonymous user with the correct status.
    active_users.each do |user|
      user.update_all status: Principal::STATUSES[:active]
    end

    deleted_user.update_all status: Principal::STATUSES[:active]
  end

  def down
    # reset system user to locked which would've been the state before this migration
    system_user.update_all status: Principal::STATUSES[:locked]

    # reset deleted usr to active which he would've been after the previous migration
    deleted_user.update_all status: Principal::STATUSES[:active]

    # There is no need to update the anonymous user since it was supposed to be
    # active at this point already anyway. The previous migration then makes it
    # built-in (0) again if we rollback even further.
  end

  def active_users
    [system_user, anonymous_user]
  end

  def system_user
    SystemUser
  end

  def anonymous_user
    AnonymousUser
  end

  def deleted_user
    DeletedUser
  end
end
