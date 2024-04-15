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

class Mails::ReminderJob < Mails::DeliverJob
  include ::Notifications::WithMarkedNotifications

  private

  def notification_marked_attribute
    :mail_reminder_sent
  end

  def render_mail
    # Have to cast to array since the update in the subsequent block
    # will result in the notification to not be found via the .unsent_reminders_before scope.
    notification_ids = Notification
                         .unsent_reminders_before(recipient:, time: Time.current)
                         .visible(recipient)
                         .pluck(:id)

    return nil if notification_ids.empty?

    with_marked_notifications(notification_ids) do
      DigestMailer
        .work_packages(recipient.id, notification_ids)
    end
  end

  # Running the digest job will take some time to complete.
  # Within this timeframe, new notifications might come in. Upon notification creation
  # a job is scheduled unless there is no prior digest notification that is not yet read (mail_reminder_sent: true).
  # If we were to only set the mail_reminder_sent state at the end of the mail rendering an edge case of the following
  # would lead to digest not being sent or at least sent unduly late:
  # * Job starts and fetches the notifications for rendering. We need to fetch all notifications to be rendered to
  #   order them as desired.
  # * Notification is created. Because there are unhandled digest notifications no job is scheduled.
  # * The above can happen repeatedly.
  # * Job ends.
  # * No new notification is generated.
  #
  # A new job would then only be scheduled upon the creation of a new digest notification which (as unlikely as that is)
  # might only happen after some days have gone by.
end
