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

class DeliverWorkPackageNotificationJob < DeliverNotificationJob
  queue_with_priority :notification

  def perform(journal_id, recipient_id, author_id)
    @journal_id = journal_id
    super(recipient_id, author_id)
  end

  def render_mail(recipient:, sender:)
    return nil unless raw_journal # abort, assuming that the underlying WP was deleted

    journal = Journal::AggregatedJournal.with_version(raw_journal)

    # The caller should have ensured that the journal can't outdate anymore
    # before queuing a notification
    raise 'aggregated journal got outdated' unless journal

    if journal.initial?
      UserMailer.work_package_added(recipient, journal, sender)
    else
      UserMailer.work_package_updated(recipient, journal, sender)
    end
  end

  private

  def raw_journal
    @raw_journal ||= Journal.find_by(id: @journal_id)
  end

  def work_package
    @work_package ||= raw_journal.journable
  end
end
