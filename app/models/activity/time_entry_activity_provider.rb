#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

  def extend_event_query(query)
    query = query.join(work_packages_table).on(activity_journals_table[:work_package_id].eq(work_packages_table[:id]))
  end

  def event_query_projection
    [
      activity_journal_projection_statement(:hours, 'time_entry_hours'),
      activity_journal_projection_statement(:comments, 'time_entry_comments'),
      activity_journal_projection_statement(:project_id, 'project_id'),
      activity_journal_projection_statement(:work_package_id, 'work_package_id'),
      projection_statement(projects_table, :name, 'project_name'),
      projection_statement(work_packages_table, :subject, 'work_package_subject')
    ]
  end

  protected

  def event_title(event)
    titry_object_name = event['work_package_id'].blank? ? event['project_name']
                                                        : event['work_package_name']
    "#urs(event['time_entry_hours'])} (#{time_entry_object_name})"
  end

  def event_description(event)
    event_data['time_entry_description']
  end

  def event_path(event)
    Rapplication.routes.url_helpers.time_entry_path(url_helper_parameter(event))
  end

  def event_url(event)
    Rapplication.routes.url_helpers.time_entry_url(url_helper_parameter(event),
                                                   host: ::Setting.host_name)
  end

  private

  def work_packages_table
    @work_packages_table ||= Arel::Table.new(:work_packages)
  end

  def projects_table
    @projects_table ||= Arel::Table.new(:projects)
  end

  def url_helper_parameter(event)
    event['journable_id']
  end
end
