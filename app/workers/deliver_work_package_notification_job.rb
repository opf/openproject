#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class DeliverWorkPackageNotificationJob
  def initialize(journal_id, author_id)
    @journal_id = journal_id
    @author_id = author_id
  end

  def perform
    # if the WP has been deleted the unaggregated journal will have been deleted too
    # and our job here is done
    return nil unless raw_journal

    journal = find_aggregated_journal

    # If we can't find the aggregated journal, it was superseded by a journal that aggregated ours.
    # In that case a job for the new journal will have been enqueued that is now responsible for
    # sending the notification. Our job here is done.
    return nil unless journal

    # TODO: move this out of the delayed job, since putting it here would require us to loop over
    # multiple predecessors
    # Send the notification on behalf of the predecessor in case it could not send the notification
    # on its own
    if hides_notifications?(journal, journal.predecessor)
      deliver_notifications_for(journal.predecessor)
    end

    unless hides_notifications?(journal.successor, journal)
      deliver_notifications_for(journal)
    end
  end

  private

  def find_aggregated_journal
    wp_journals = Journal::AggregatedJournal.aggregated_journals(journable: work_package)
    wp_journals.detect { |journal| journal.version == raw_journal.version }
  end

  # Returns whether "notification-hiding" should be assumed. This leads to an aggregated journal
  # effectively blocking notifications of an earlier journal. See the specs section under
  # "mail suppressing aggregation" for more details
  def hides_notifications?(successor, predecessor)
    return false unless successor && predecessor

    timeout = Setting.journal_aggregation_time_minutes.to_i.minutes

    if successor.user_id != predecessor.user_id ||
      (successor.created_at - predecessor.created_at) <= timeout
      return false
    end

    # imaginary state in which the successor never existed
    # if this leads to a state change of the predecessor, the successor must have taken journals
    # from it.
    pred_without_succ = Journal::AggregatedJournal.aggregated_journals(
      journable: work_package,
      until_version: successor.notes_version - 1).last

    predecessor.id != pred_without_succ.id
  end

  def deliver_notifications_for(journal)
    notification_receivers(work_package).uniq.each do |recipient|
      mail = User.execute_as(recipient) {
        if journal.initial?
          UserMailer.work_package_added(recipient, work_package, author)
        else
          UserMailer.work_package_updated(recipient, journal, author)
        end
      }

      mail.deliver
    end
  end

  def notification_receivers(work_package)
    work_package.recipients + work_package.watcher_recipients
  end

  def raw_journal
    @raw_journal ||= Journal.find_by_id(@journal_id)
  end

  def work_package
    @work_package ||= raw_journal.journable
  end

  def author
    @author ||= User.find_by_id(@author_id) || DeletedUser.first
  end
end
