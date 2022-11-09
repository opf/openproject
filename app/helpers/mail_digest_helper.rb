#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
  def digest_summary_text(notification_count, mentioned_count)
    mentioned = mentioned_count > 1 ? 'plural' : 'singular'
    notifications = notification_count > 1 ? 'plural' : 'singular'

    summary = I18n.t(:"mail.digests.unread_notification_#{notifications}",
                     number_unread: notification_count).to_s

    unless mentioned_count === 0
      summary << " #{I18n.t(:"mail.digests.including_mention_#{mentioned}",
                            number_mentioned: mentioned_count)}"
    end

    summary
  end

  def date_alerts_text(notification)
    work_package = notification.resource
    date_value = date_value(notification, work_package)

    alert_text = if date_value
                   date_is_past = date_value.before?(Time.zone.today)
                   is_overdue = date_is_past && (notification.reason == "date_alert_due_date" || work_package.milestone?)
                   days_diff = (date_value - Time.zone.today).to_i.abs

                   build_alert_text(days_diff, is_overdue, date_is_past)
                 else
                   I18n.t('js.notifications.date_alerts.property_is_deleted')
                 end

    "#{property_text(notification, is_overdue, days_diff)} #{alert_text}"
  end

  def date_value(notification, work_package)
    notification.reason == "date_alert_start_date" ? work_package.start_date : work_package.due_date
  end

  def property_text(notification, is_overdue, days_diff)
    if is_overdue && days_diff > 0
      I18n.t('js.notifications.date_alerts.overdue')
    else
      property_text_helper(notification)
    end
  end

  def build_alert_text(days_diff, is_overdue, date_is_past)
    days_text = I18n.t('js.units.day', count: days_diff)

    return 'is today' if days_diff == 0
    return "since #{days_text}" if is_overdue
    return "was #{days_text} ago" if date_is_past

    "is in #{days_text}"
  end

  def property_text_helper(notification)
    return I18n.t('js.notifications.date_alerts.milestone_date') if notification.resource.milestone?

    if notification.reason == "date_alert_start_date"
      I18n.t('js.work_packages.properties.startDate')
    else
      I18n.t('js.work_packages.properties.dueDate')
    end
  end

  def digest_notification_timestamp_text(notification, html: true)
    journal = notification.journal
    user = html ? link_to_user(journal.user, only_path: false) : journal.user.name

    timestamp_text(user, journal)
  end

  def digest_additional_author_text(notifications)
    number_of_additional_authors = number_of_authors(notifications) - 1

    if notifications.length > 1 && number_of_additional_authors > 0
      amount = number_of_additional_authors === 1 ? 'one' : 'other'
      I18n.t(:"js.notifications.center.and_more_users.#{amount}", count: number_of_additional_authors)
    end
  end

  private

  def timestamp_text(user, journal)
    value = journal.initial? ? "created" : "updated"
    sanitize(
      I18n.t(:"mail.work_packages.#{value}_at",
             user:,
             timestamp: journal.created_at.strftime(
               "#{I18n.t(:'date.formats.default')}, #{I18n.t(:'time.formats.time')}"
             ))
    )
  end

  def number_of_authors(notifications)
    notifications.group_by { |n| n[:actor_id] }.count
  end
end
