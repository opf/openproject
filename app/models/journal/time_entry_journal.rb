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

class Journal::TimeEntryJournal < Journal::BaseJournal
  self.table_name = "time_entry_journals"

  acts_as_activity_provider type: 'time_entries',
                            permission: :view_time_entries

  def self.extend_event_query(j, ej, query)
    w = Arel::Table.new(:work_packages)

    query = query.join(w).on(ej[:work_package_id].eq(w[:id]))
    [ej, query]
  end

  def self.event_query_projection(j, ej)
    p = Arel::Table.new(:projects)
    w = Arel::Table.new(:work_packages)

    [
      ej[:hours].as('time_entry_hours'),
      ej[:comments].as('time_entry_comments'),
      ej[:project_id].as('project_id'),
      ej[:work_package_id].as('work_package_id'),
      p[:name].as('project_name'),
      w[:subject].as('work_package_subject'),
    ]
  end

  def self.format_event(event, event_data)
    event.event_title = self.event_title event_data
    event.event_description = event_data['time_entry_description']
    event.event_path = self.event_path event_data
    event.event_url = self.event_url event_data

    event
  end

  private

  def self.event_title(event)
    time_entry_object_name = event['work_package_id'].blank? ? event['project_name']
                                                             : event['work_package_name']
    "#{l_hours(event['time_entry_hours'])} (#{time_entry_object_name})"
  end

  def self.event_path(event)
    Rails.application.routes.url_helpers.time_entry_path(self.url_helper_parameter(event))
  end

  def self.event_url(event)
    Rails.application.routes.url_helpers.time_entry_url(self.url_helper_parameter(event))
  end

  def self.url_helper_parameter(event)
    { id: event['journable_id'] }
  end
end
