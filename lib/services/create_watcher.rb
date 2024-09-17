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

class Services::CreateWatcher
  def initialize(work_package, user)
    @work_package = work_package
    @user = user

    @watcher = Watcher.new(user:, watchable: work_package)
  end

  def run(send_notifications: nil, success: ->(*) {}, failure: ->(*) {})
    send_notifications = Journal::NotificationConfiguration.active? if send_notifications.nil?
    if @work_package.watcher_users.include?(@user)
      success.(created: false)
    elsif @watcher.valid?
      @work_package.watchers << @watcher
      success.(created: true)
      OpenProject::Notifications.send(OpenProject::Events::WATCHER_ADDED,
                                      watcher: @watcher,
                                      watcher_setter: User.current,
                                      send_notifications:)
    else
      failure.(@watcher)
    end
  end
end
