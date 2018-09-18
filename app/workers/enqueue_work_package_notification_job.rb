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

# Enqueues
class EnqueueWorkPackageNotificationJob < ApplicationJob
  def initialize(journal_id, author_id)
    @journal_id = journal_id
    @author_id = author_id
  end

  def perform
    # if the WP has been deleted the unaggregated journal will have been deleted too
    # and our job here is done
    return nil unless raw_journal

    @journal = find_aggregated_journal

    # If we can't find the aggregated journal, it was superseded by a journal that aggregated ours.
    # In that case a job for the new journal will have been enqueued that is now responsible for
    # sending the notification. Our job here is done.
    return nil unless @journal

    @author = User.find_by(id: @author_id) || DeletedUser.first

    # Do not deliver notifications if a follow-up journal will already have sent a notification
    # on behalf of this job.
    unless Journal::AggregatedJournal.hides_notifications?(@journal.successor, @journal)
      deliver_notifications_for(@journal)
    end
  end

  private

  def find_aggregated_journal
    wp_journals = Journal::AggregatedJournal.aggregated_journals(journable: work_package)
    wp_journals.detect { |journal| journal.version == raw_journal.version }
  end

  def deliver_notifications_for(journal)
    notification_receivers(work_package).each do |recipient|
      job = DeliverWorkPackageNotificationJob.new(journal.id, recipient.id, @author_id)
      Delayed::Job.enqueue job, priority: ::ApplicationJob.priority_number(:notification)
    end

    OpenProject::Notifications.send(
      OpenProject::Events::AGGREGATED_WORK_PACKAGE_JOURNAL_READY,
      journal_id: journal.id,
      initial: journal.initial?
    )
  end

  def raw_journal
    @raw_journal ||= Journal.find_by(id: @journal_id)
  end

  def work_package
    @work_package ||= raw_journal.journable
  end

  def notification_receivers(work_package)
    (work_package.recipients + work_package.watcher_recipients + mentioned).uniq
  end

  def mentioned
    mentioned_ids
      .where(id: User.allowed(:view_work_packages, @work_package.project))
      .where.not(mail_notification: User::USER_MAIL_OPTION_NON.first)
  end

  def text_for_mentions
    potential_text = ""
    potential_text << @journal.notes if @journal.try(:notes)

    %i[description subject].each do |field|
      if @journal.details[field].try(:any?)
        from = @journal.details[field].first
        to = @journal.details[field].second
        potential_text << "\n" + Redmine::Helpers::Diff.new(to, from).additions.join(' ')
      end
    end
    potential_text
  end

  def mentioned_ids
    text = text_for_mentions
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
end
