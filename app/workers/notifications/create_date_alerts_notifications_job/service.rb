#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Notifications::CreateDateAlertsNotificationsJob::Service
  def initialize(user)
    @user = user
  end

  def call
    return unless EnterpriseToken.allows_to?(:date_alerts)

    Time.use_zone(user.time_zone) do
      send_date_alert_notifications(user)
    end
  end

  private

  attr_accessor :user

  def send_date_alert_notifications(user)
    alertables = Notifications::CreateDateAlertsNotificationsJob::AlertableWorkPackages.new(user)
    create_date_alert_notifications(user, alertables.alertable_for_start, :date_alert_start_date)
    create_date_alert_notifications(user, alertables.alertable_for_due, :date_alert_due_date)
  end

  def create_date_alert_notifications(user, work_packages, reason)
    mark_previous_notifications_as_read(user, work_packages, reason)
    work_packages.find_each do |work_package|
      create_date_alert_notification(user, work_package, reason)
    end
  end

  def mark_previous_notifications_as_read(user, work_packages, reason)
    return if work_packages.empty?

    Notification
      .where(recipient: user,
             reason:,
             resource: work_packages)
      .update_all(read_ian: true, updated_at: Time.current)
  end

  def create_date_alert_notification(user, work_package, reason)
    create_service = Notifications::CreateService.new(user:)
    create_service.call(
      recipient_id: user.id,
      project_id: work_package.project_id,
      resource: work_package,
      reason:
    )
  end
end
