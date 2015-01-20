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

class Activity::TimeEntryActivityProvider < Activity::BaseActivityProvider
  acts_as_activity_provider type: 'time_entries',
                            permission: :view_time_entries

  def extend_event_query(query, activity)
    query.join(work_packages_table).on(activity_journals_table(activity)[:work_package_id].eq(work_packages_table[:id]))
    query.join(types_table).on(work_packages_table[:type_id].eq(types_table[:id]))
    query.join(statuses_table).on(work_packages_table[:status_id].eq(statuses_table[:id]))
  end

  def event_query_projection(activity)
    [
      activity_journal_projection_statement(:hours, 'time_entry_hours', activity),
      activity_journal_projection_statement(:comments, 'time_entry_comments', activity),
      activity_journal_projection_statement(:project_id, 'project_id', activity),
      activity_journal_projection_statement(:work_package_id, 'work_package_id', activity),
      projection_statement(projects_table, :name, 'project_name'),
      projection_statement(work_packages_table, :subject, 'work_package_subject'),
      projection_statement(statuses_table, :name, 'status_name'),
      projection_statement(statuses_table, :is_closed, 'status_closed'),
      projection_statement(types_table, :name, 'type_name')
    ]
  end

  protected

  def event_title(event, _activity)
    time_entry_object_name = event['work_package_id'].blank? ? event['project_name']
                                                             : work_package_title(event)
    "#{l_hours(event['time_entry_hours'])} (#{time_entry_object_name})"
  end

  def event_type(_event, _activity)
    'time-entry'
  end

  def work_package_title(event)
    Activity::WorkPackageActivityProvider.work_package_title(event['work_package_id'],
                                                             event['work_package_subject'],
                                                             event['type_name'],
                                                             event['status_name'],
                                                             event['is_standard'])
  end

  def event_description(event, _activity)
    event['time_entry_description']
  end

  def event_path(event, _activity)
    unless event['work_package_id'].blank?
      url_helpers.work_package_time_entries_path(event['work_package_id'])
    else
      url_helpers.project_time_entries_path(event['project_id'])
    end
  end

  def event_url(event, _activity)
    unless event['work_package_id'].blank?
      url_helpers.work_package_time_entries_url(event['work_package_id'])
    else
      url_helpers.project_time_entries_url(event['project_id'])
    end
  end
end
