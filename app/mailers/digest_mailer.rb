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

# Sends digest mails. Digest mails contain the combined information of multiple updates to
# resources.
# Currently, this is limited to work packages

class DigestMailer < ApplicationMailer
  include OpenProject::StaticRouting::UrlHelpers
  include OpenProject::TextFormatting
  include Redmine::I18n
  include MailDigestHelper
  include MailNotificationHelper

  helper :mail_digest,
         :mail_notification

  MAX_SHOWN_WORK_PACKAGES = 15

  class << self
    def generate_message_id(_, user)
      hash = "openproject.digest-#{user.id}-#{Time.current.strftime('%Y%m%d%H%M%S')}"
      host = Setting.mail_from.to_s.gsub(%r{\A.*@}, "")
      host = "#{::Socket.gethostname}.openproject" if host.empty?
      "#{hash}@#{host}"
    end
  end

  def work_packages(recipient_id, notification_ids)
    recipient = User.find(recipient_id)

    open_project_headers User: recipient.name
    message_id "digest", recipient

    @user = recipient
    @notification_ids = notification_ids
    @aggregated_notifications = load_notifications(notification_ids)
                                  .sort_by(&:created_at)
                                  .reverse
                                  .group_by(&:resource)

    @mentioned_count = @aggregated_notifications
                         .values
                         .flatten
                         .filter_map(&:reason)
                         .count("mentioned")

    return if @aggregated_notifications.empty?

    send_localized_mail(recipient) do
      "#{Setting.app_title} - #{digest_summary_text(notification_ids.size, @mentioned_count)}"
    end
  end

  protected

  def load_notifications(notification_ids)
    Notification
      .where(id: notification_ids)
      .includes(:resource)
      .reject do |notification|
        notification.resource.nil? ||
        (notification.journal.nil? && !notification.date_alert?)
      end
  end
end
