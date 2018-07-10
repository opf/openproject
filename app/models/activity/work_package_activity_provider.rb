#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class Activity::WorkPackageActivityProvider < Activity::BaseActivityProvider
  acts_as_activity_provider type: 'work_packages',
                            permission: :view_work_packages

  def extend_event_query(query, activity)
    query.join(types_table).on(activity_journals_table(activity)[:type_id].eq(types_table[:id]))
    query.join(statuses_table).on(activity_journals_table(activity)[:status_id].eq(statuses_table[:id]))
  end

  def event_query_projection(activity)
    [
      activity_journal_projection_statement(:subject, 'subject', activity),
      activity_journal_projection_statement(:project_id, 'project_id', activity),
      projection_statement(statuses_table, :name, 'status_name'),
      projection_statement(statuses_table, :is_closed, 'status_closed'),
      projection_statement(types_table, :name, 'type_name')
    ]
  end

  def self.work_package_title(id, subject, type_name, status_name, is_standard)
    title = "#{(is_standard) ? '' : "#{type_name}"} ##{id}: #{subject}"
    title << " (#{status_name})" unless status_name.blank?
  end

  protected

  def event_title(event, _activity)
    self.class.work_package_title(event['journable_id'],
                                  event['subject'],
                                  event['type_name'],
                                  event['status_name'],
                                  event['is_standard'])
  end

  def event_type(event, _activity)
    state = ActiveRecord::Type::Boolean.new.cast(event['status_closed']) ? '-closed' : '-edit'

    "work_package#{state}"
  end

  def event_path(event, _activity)
    url_helpers.work_package_path(event['journable_id'])
  end

  def event_url(event, _activity)
    url_helpers.work_package_url(event['journable_id'],
                                 anchor: notes_anchor(event))
  end

  private

  def notes_anchor(event)
    version = event['version'].to_i

    (version > 1) ? "note-#{version - 1}" : ''
  end
end
