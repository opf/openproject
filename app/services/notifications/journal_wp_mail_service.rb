#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

class Notifications::JournalWpMailService
  class << self
    include Notifications::JournalNotifier

    def call(journal, send_mails)
      journal_complete_mail(journal, send_mails)
    end

    private

    def journal_complete_mail(journal, send_mails)
      return nil if abort_sending?(journal, send_mails)

      author = User.find_by(id: journal.user_id) || DeletedUser.first

      notification_receivers(journal.journable, journal).each do |recipient|
        DeliverWorkPackageNotificationJob.perform_later(journal.id, recipient.id, author.id)
      end
    end

    def notification_receivers(work_package, journal)
      (work_package.recipients + work_package.watcher_recipients + mentioned(work_package, journal)).uniq
    end

    def mentioned(work_package, journal)
      mentioned_ids(journal)
        .where(id: User.allowed(:view_work_packages, work_package.project))
        .where.not(mail_notification: User::USER_MAIL_OPTION_NON.first)
    end

    def text_for_mentions(journal)
      potential_text = ""
      potential_text << journal.notes if journal.try(:notes)

      %i[description subject].each do |field|
        details = journal.details[field]

        if details.present?
          potential_text << "\n" + Redmine::Helpers::Diff.new(*details).additions.join(' ')
        end
      end
      potential_text
    end

    def mentioned_ids(journal)
      text = text_for_mentions(journal)
      user_ids, user_login_names, group_ids = text
                                              .scan(/\b(?:user#([\d]+))|(?:user:"(.+?)")|(?:group#([\d]+))\b/)
                                              .transpose
                                              .each(&:compact!)

      base_scope = User
                   .includes(:groups)
                   .references(:groups_users)

      by_id = base_scope.where(id: user_ids || [])
      by_login = base_scope.where(login: user_login_names || [])
      by_group = base_scope.where(groups_users: { id: group_ids || [] })

      by_id
        .or(by_login)
        .or(by_group)
    end

    def send_mail?(journal, send_mails)
      send_mails && ::UserMailer.perform_deliveries && send_mail_setting?(journal)
    end

    def send_mail_setting?(journal)
      notify_for_wp_added?(journal) ||
        notify_for_wp_updated?(journal) ||
        notify_for_notes?(journal) ||
        notify_for_status?(journal) ||
        notify_for_priority(journal)
    end

    def notify_for_wp_added?(journal)
      notification_enabled?('work_package_added') && journal.initial?
    end

    def notify_for_wp_updated?(journal)
      notification_enabled?('work_package_updated') && !journal.initial?
    end

    def notify_for_notes?(journal)
      notification_enabled?('work_package_note_added') && journal.notes.present?
    end

    def notify_for_status?(journal)
      notification_enabled?('status_updated') &&
        journal.details.has_key?(:status_id)
    end

    def notify_for_priority(journal)
      notification_enabled?('work_package_priority_updated') &&
        journal.details.has_key?(:priority_id)
    end

    def notification_enabled?(name)
      Setting.notified_events.include?(name)
    end

    def abort_sending?(journal, send_mails)
      !send_mail?(journal, send_mails) || journal.noop?
    end
  end
end
