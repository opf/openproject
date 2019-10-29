#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

module Notifications::JournalNotifier
  private

  def find_aggregated_journal_for(raw_journal)
    Journal::AggregatedJournal.with_version(raw_journal)
  end

  def notify_journal_complete(work_package, journal, send_mails)
    journal_complete_mail(work_package, journal, send_mails)

    journal_complete_notification(journal)
  end

  def journal_complete_mail(work_package, journal, send_mails)
    return nil unless send_mail?(journal, send_mails)

    notification_receivers(work_package, journal).each do |recipient|
      job = DeliverWorkPackageNotificationJob.new(journal.id,
                                                  recipient.id,
                                                  User.current.id)
      Delayed::Job.enqueue job, priority: ::ApplicationJob.priority_number(:notification)
    end
  end

  def journal_complete_notification(journal)
    OpenProject::Notifications.send(
      OpenProject::Events::AGGREGATED_WORK_PACKAGE_JOURNAL_READY,
      journal_id: journal.id,
      initial: journal.initial?
    )
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
      if journal.details[field].try(:any?)
        from = journal.details[field].first
        to = journal.details[field].second
        potential_text << "\n" + Redmine::Helpers::Diff.new(to, from).additions.join(' ')
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
    (Setting.notified_events.include?('work_package_added') && journal.initial?) ||
      (Setting.notified_events.include?('work_package_updated') && !journal.initial?) ||
      notify_for_notes?(journal) ||
      notify_for_status?(journal) ||
      notify_for_priority(journal)
  end

  def notify_for_notes?(journal)
    Setting.notified_events.include?('work_package_note_added') && journal.notes.present?
  end

  def notify_for_status?(journal)
    Setting.notified_events.include?('status_updated') &&
      journal.details.has_key?(:status_id)
  end

  def notify_for_priority(journal)
    Setting.notified_events.include?('work_package_priority_updated') &&
      journal.details.has_key?(:priority_id)
  end
end
