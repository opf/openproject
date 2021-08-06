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

class Notifications::ScheduleJournalMailsService
  class << self
    def call(journal)
      schedule_direct_mail_jobs(journal)
      schedule_digest_mail_jobs(journal)
    end

    protected

    def schedule_direct_mail_jobs(journal)
      journal.notifications.unread_mail.each do |notification|
        schedule_direct_mail_job(notification)
      end
    end

    def schedule_digest_mail_jobs(journal)
      journal.notifications.unread_mail_digest.each do |notification|
        schedule_digest_mail_job(notification)
      end
    end

    def schedule_direct_mail_job(notification)
      Mails::NotificationJob
        .set(wait: Setting.notification_email_delay_minutes.minutes)
        .perform_later(notification)
    end

    def schedule_digest_mail_job(notification)
      # This alone is vulnerable to the edge case of the Mails::DigestJob
      # having started but not completed when a new digest notification is generated.
      # To cope with it, the Mails::DigestJob as its first action sets all digest notifications
      # to being handled even though they are still processed.
      # See the DigestJob for more details.
      return if digest_job_already_scheduled?(notification)

      Mails::DigestJob
        .set(wait_until: Mails::DigestJob.execution_time(notification.recipient))
        .perform_later(notification.recipient)
    end

    def digest_job_already_scheduled?(notification)
      Notification
        .mail_digest_before(recipient: notification.recipient,
                            time: notification.created_at)
        .where.not(id: notification.id)
        .exists?
    end
  end
end
