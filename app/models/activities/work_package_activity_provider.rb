# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Activities::WorkPackageActivityProvider < Activities::BaseActivityProvider
  activity_provider_for type: 'work_packages',
                        permission: :view_work_packages

  def extend_event_query(query)
    query.join(types_table).on(activity_journals_table[:type_id].eq(types_table[:id]))
    query.join(statuses_table).on(activity_journals_table[:status_id].eq(statuses_table[:id]))
  end

  def event_query_projection
    [
      activity_journal_projection_statement(:subject, 'subject'),
      activity_journal_projection_statement(:project_id, 'project_id'),
      projection_statement(statuses_table, :is_closed, 'status_closed'),
      projection_statement(types_table, :name, 'type_name')
    ]
  end

  def self.work_package_title(id, subject, type_name)
    "#{type_name} ##{id}: #{subject}"
  end

  protected

  def event_title(event)
    self.class.work_package_title(event['journable_id'],
                                  event['subject'],
                                  event['type_name'])
  end

  def event_type(event)
    event['status_closed'] ? 'work_package-closed' : 'work_package-edit'
  end

  def event_path(event)
    url_helpers.work_package_path(event['journable_id'])
  end

  def event_url(event)
    url_helpers.work_package_url(event['journable_id'],
                                 anchor: notes_anchor(event))
  end

  private

  def notes_anchor(event)
    version = event['version'].to_i

    version > 1 ? "note-#{version - 1}" : ''
  end

  def types_table
    @types_table = Type.arel_table
  end

  def statuses_table
    @statuses_table = Status.arel_table
  end
end
