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
  include OpenProject::BeforeDelayedJob

  def initialize(journal_id, author_id)
    @journal_id = journal_id
    @author_id = author_id
  end

  def perform
    return unless raw_journal # abort, assuming that the underlying WP was deleted

    journal = find_aggregated_journal

    # The caller should have ensured that the journal can't outdate anymore
    # before queuing a notification
    raise 'aggregated journal got outdated' unless journal

    notification_receivers(work_package).uniq.each do |recipient|
      mail = User.execute_as(recipient) {
        if journal.initial?
          UserMailer.work_package_added(recipient, journal, author)
        else
          UserMailer.work_package_updated(recipient, journal, author)
        end
      }

      mail.deliver_now
    end
  end

  private

  def find_aggregated_journal
    wp_journals = Journal::AggregatedJournal.aggregated_journals(journable: work_package)
    wp_journals.detect { |journal| journal.version == raw_journal.version }
  end

  def notification_receivers(work_package)
    work_package.recipients + work_package.watcher_recipients
  end

  def raw_journal
    @raw_journal ||= Journal.find_by(id: @journal_id)
  end

  def work_package
    @work_package ||= raw_journal.journable
  end

  def author
    @author ||= User.find_by(id: @author_id) || DeletedUser.first
  end
end
