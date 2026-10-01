# frozen_string_literal: true

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

class Reminders::NotificationMailer < ApplicationMailer
  include MailNotificationHelper
  include Redmine::I18n

  helper :mail_notification
  helper_method :reminder_summary_text,
                :reminder_timestamp_text,
                :reminder_note_text,
                :work_package_subject_text_wrapper,
                :text_email_wrapper

  def reminder_notification(notification)
    @notification = notification
    @user = notification.recipient
    @work_package = notification.resource
    @reminder = notification.reminder

    open_project_headers User: notification.recipient.name
    message_id "reminder", notification.recipient

    send_localized_mail(notification.recipient) do
      "#{Setting.app_title} - #{email_subject_suffix}"
    end
  end

  private

  def email_subject_suffix
    note = @reminder.note.presence || @work_package.subject
    I18n.t(:"mail.reminder_notifications.subject", note:)
  end

  def reminder_summary_text
    I18n.t(:"mail.reminder_notifications.heading")
  end

  def reminder_timestamp_text
    "#{format_time(@notification.created_at)}."
  end

  def reminder_note_text
    return if @reminder.note.blank?

    I18n.t(:"mail.reminder_notifications.note", note: @reminder.note)
  end

  def work_package_subject_text_wrapper
    "=" * ("#{@work_package.formatted_id} #{@work_package.subject}".length + 4)
  end

  def text_email_wrapper
    "-" * 100
  end
end
