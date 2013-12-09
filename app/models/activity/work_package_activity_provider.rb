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

class Activity::WorkPackageActivityProvider < Activity::BaseActivityProvider
  include Redmine::I18n

  acts_as_activity_provider type: 'work_packages',
                            permission: :view_work_packages

  def extend_event_query(query)
    query.join(types_table).on(activity_journals_table[:type_id].eq(types_table[:id]))
    query.join(statuses_table).on(activity_journals_table[:status_id].eq(statuses_table[:id]))
  end

  def event_query_projection
    [
      activity_journals_table[:subject].as('subject'),
      activity_journals_table[:project_id].as('project_id'),
      statuses_table[:name].as('status_name'),
      statuses_table[:is_closed].as('status_closed'),
      types_table[:name].as('type_name')
    ]
  end

  def format_event(event, event_data)
    event.event_title = event_title event_data
    event.event_type = "work_package#{event_type event_data}"
    event.event_path = event_path event_data
    event.event_url = event_url event_data

    event
  end

  private

  def types_table
    @types_table = Arel::Table.new(:types)
  end

  def statuses_table
    @statuses_table = Arel::Table.new(:statuses)
  end

  def event_title(event)
    title = "#{(event['is_standard']) ? l(:default_type)
                                        : "#{event['type_name']}"} ##{event['journable_id']}: #{event['subject']}"
    title << " (#{event['status_name']})" unless event['status_name'].blank?
  end

  def event_type(event)
    journal = Journal.find(event['event_id'])

    if journal.changed_data.empty? && !journal.initial?
      '-note'
    else
      event['status_closed'] ? '-closed' : '-edit'
    end
  end

  def event_path(event)
    Rails.application.routes.url_helpers.work_package_path(url_helper_parameter(event))
  end

  def event_url(event)
    Rails.application.routes.url_helpers.work_package_url(url_helper_parameter(event),
                                                          host: ::Setting.host_name)
  end

  def url_helper_parameter(event)
    version = event['version'].to_i
    anchor = event['version'].to_i - 1

    parameters = [event['journable_id']]
    parameters << { anchor: "note-#{anchor}" } if version > 1
    parameters
  end
end
