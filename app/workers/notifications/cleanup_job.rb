#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

module Notifications
  class CleanupJob < ::Cron::CronJob
    DEFAULT_RETENTION ||= 30

    # runs at 2:22 nightly
    self.cron_expression = '22 2 * * *'

    def perform
      Notification
        .where('updated_at < ?', oldest_notification_retention_time)
        .delete_all
    end

    private

    def oldest_notification_retention_time
      days_ago = Setting.notification_retention_period_days.to_i
      days_ago = DEFAULT_RETENTION if days_ago <= 0

      Time.zone.today - days_ago.days
    end
  end
end
