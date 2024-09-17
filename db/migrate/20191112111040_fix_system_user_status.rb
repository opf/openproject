#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

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
      user.update_all status: Principal.statuses[:active]
    end

    deleted_user.update_all status: Principal.statuses[:active]
  end

  def down
    # reset system user to locked which would've been the state before this migration
    system_user.update_all status: Principal.statuses[:locked]

    # reset deleted usr to active which he would've been after the previous migration
    deleted_user.update_all status: Principal.statuses[:active]

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
