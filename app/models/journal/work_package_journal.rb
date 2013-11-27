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

class Journal::WorkPackageJournal < Journal::BaseJournal
  self.table_name = "work_package_journals"

  acts_as_activity_provider type: 'work_packages',
                            permission: :view_work_packages

  def self.extend_event_query(j, ej, query)
    t = Arel::Table.new(:types)
    s = Arel::Table.new(:statuses)

    query = query.join(t).on(ej[:type_id].eq(t[:id]))
    query = query.join(s).on(ej[:status_id].eq(s[:id]))
    [ej, query]
  end

  def self.event_query_projection(j, ej)
    t = Arel::Table.new(:types)
    s = Arel::Table.new(:statuses)

    [
      ej[:subject].as('subject'),
      ej[:project_id].as('project_id'),
      s[:name].as('status_name'),
      s[:is_closed].as('status_closed'),
      t[:name].as('type_name')
    ]
  end

  def self.format_event(event, event_data)
    event.title = self.event_title event_data
    event.project_id = event_data['project_id'].to_i
    event.type << "#{self.event_type event_data}"
    event.url = self.event_url event_data

    event
  end

  private

  def self.event_title(event)
    title = "#{(event['is_standard']) ? l(:default_type)
                                      : "#{event['type_name']}"} ##{event['journable_id']}: #{event['subject']}"
    title << " (#{event['status_name']})" unless event['status_name'].blank?
  end

  def self.event_type(event)
    journal = Journal.find(event['event_id'])

    if journal.changed_data.empty? && !journal.initial?
       '-note'
    else
      event['status_closed'] ? '-closed' : '-edit'
    end
  end

  def self.event_url(event)
    version = event['version'].to_i
    anchor = event['version'].to_i - 1
    parameters = { id: event['journable_id'], anchor: (version > 1 ? "note-#{anchor}" : '') }

    Rails.application.routes.url_helpers.work_package_path(parameters)
  end
end
