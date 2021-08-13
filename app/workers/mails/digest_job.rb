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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Mails::DigestJob < Mails::DeliverJob
  class << self
    def schedule(notification)
      # This alone is vulnerable to the edge case of the Mails::DigestJob
      # having started but not completed when a new digest notification is generated.
      # To cope with it, the Mails::DigestJob as its first action sets all digest notifications
      # to being handled even though they are still processed.
      # See the DigestJob for more details.
      return if digest_job_already_scheduled?(notification)

      set(wait_until: execution_time(notification.recipient))
        .perform_later(notification.recipient)
    end

    private

    def execution_time(user)
      zone = (user.time_zone || ActiveSupport::TimeZone.new('UTC'))

      zone.parse(Setting.notification_email_digest_time) + 1.day
    end

    def digest_job_already_scheduled?(notification)
      Notification
        .mail_digest_before(recipient: notification.recipient,
                            time: notification.created_at)
        .where.not(id: notification.id)
        .exists?
    end
  end

  private

  def render_mail
    # Have to cast to array since the update in the subsequent block
    # will result in the notification to not be found via the .mail_digest_before scope.
    notification_ids = Notification.mail_digest_before(recipient: recipient, time: Time.current).pluck(:id)

    return nil if notification_ids.empty?

    with_marked_notifications(notification_ids) do
      DigestMailer
        .work_packages(recipient.id, notification_ids)
    end
  end

  # Running the digest job will take some time to complete.
  # Within this timeframe, new notifications might come in. Upon notification creation
  # a job is scheduled unless there is no prior digest notification that is not yet read (read_mail_digest: true).
  # If we were to only set the read_mail_digest state at the end of the mail rendering an edge case of the following
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
  #
  # Because we mark the notifications as read even though they in fact aren't, we do it in a transaction
  # so that the change is rolled back in case of an error.
  def with_marked_notifications(notification_ids)
    Notification.transaction do
      mark_notifications_read(notification_ids)

      yield
    end
  end

  def mark_notifications_read(notification_ids)
    Notification.where(id: notification_ids).update_all(read_mail_digest: true, updated_at: Time.current)
  end
end
