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

# Enqueues
class EnqueueWorkPackageNotificationJob < ApplicationJob
  queue_with_priority :notification

  include Notifications::JournalNotifier

  def perform(journal_id, send_mails)
    # This is caused by a DJ job running as ActiveJob
    @journal_id = journal_id
    @send_mails = send_mails

    # if the WP has been deleted the unaggregated journal will have been deleted too
    # and our job here is done
    return unless raw_journal

    journal = find_aggregated_journal_for(raw_journal)

    # If we can't find the aggregated journal, it was superseded by a journal that aggregated ours.
    # In that case a job for the new journal will have been enqueued that is now responsible for
    # sending the notification. Our job here is done.
    return unless journal

    # Send the notification on behalf of the predecessor in case it could not send it on its own
    notify_for_wp_predecessor(journal)

    notify_for_journal(journal)
  end

  private

  def notify_for_journal(journal)
    # Do not deliver notifications if a follow-up journal will already have sent a notification
    # on behalf of this job.
    return if Journal::AggregatedJournal.hides_notifications?(journal.successor, journal)

    notify_journal_complete(journal, @send_mails)
  end

  def notify_for_wp_predecessor(aggregated)
    return unless Journal::AggregatedJournal.hides_notifications?(aggregated, aggregated.predecessor)

    aggregated_predecessor = find_aggregated_journal_for(aggregated.predecessor)
    notify_journal_complete(aggregated_predecessor, @send_mails)
  end

  def raw_journal
    @raw_journal ||= Journal.find_by(id: @journal_id)
  end

  def work_package
    @work_package ||= raw_journal.journable
  end
end
