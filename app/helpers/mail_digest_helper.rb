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

module MailDigestHelper
  include ::ColorsHelper

  def digest_timespan_text(notification_count, wp_count)
    date = Time.parse(Setting.notification_email_digest_time)

    I18n.t(:"mail.digests.time_frame",
           time: Setting.notification_email_digest_time,
           weekday: day_name(date.wday),
           date: ::I18n.l(date.to_date, format: :long),
           number_unread: notification_count,
           number_work_packages: wp_count)
  end

  def digest_notification_timestamp_text(notification, html: true, extended_text: false)
    journal = notification.journal
    user = html ? link_to_user(journal.user, only_path: false) : journal.user.name

    timestamp_text(user, journal, extended_text)
  end

  def unique_reasons_of_notifications(notifications)
    notifications
      .map(&:reason_mail_digest)
      .uniq
  end

  def notifications_path(id)
    notifications_center_url(['details', id, 'activity'])
  end

  def type_color(type)
    color_id = selected_color(type)
    Color.find(color_id).hexcode
  end

  def status_colors(object)
    color_id = selected_color(object)
    Color.find(color_id).color_styles.map { |k, v| "#{k}:#{v};" }.join(' ')
  end

  private

  def timestamp_text(user, journal, extended)
    value = journal.initial? ? "created" : "updated"
    if extended
      raw(I18n.t(:"mail.digests.work_packages.#{value}") +
            ' ' +
            I18n.t(:"mail.digests.work_packages.#{value}_at",
                   user: user,
                   timestamp: time_ago_in_words(journal.created_at)))
    else
      raw(I18n.t(:"mail.digests.work_packages.#{value}_at",
                 user: user,
                 timestamp: time_ago_in_words(journal.created_at)))
    end
  end
end
