#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2011-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

class Activity::MeetingActivityProvider
  include Redmine::Acts::ActivityProvider
  include Redmine::I18n
  
  acts_as_activity_provider type: 'meetings',
                            classes: [ Meeting, MeetingContent ],
                            permission: :view_meetings

  def self.extend_event_query(j, ej, query)
    if ej.name == 'meeting_journals'
      [ej, query]
    else
      m = Arel::Table.new(:meetings)
      mc = Arel::Table.new(:meeting_contents)

      query = query.join(m).on(ej[:meeting_id].eq(m[:id]))
      join_cond = j[:journable_type].eq("MeetingContent")
      query = query.join(mc).on(j[:journable_id].eq(mc[:id]).and(join_cond))

      [m, query]
    end
  end

  def self.event_query_projection(j, ej)
    if ej.name == 'meeting_journals'
      [
        ej[:title].as('meeting_title'),
        ej[:start_time].as('meeting_start_time'),
        ej[:duration].as('meeting_duration'),
        ej[:project_id].as('project_id')
      ]
    else
      m = Arel::Table.new(:meetings)
      mc = Arel::Table.new(:meeting_contents)

      [
        mc[:type].as('meeting_content_type'),
        m[:id].as('meeting_id'),
        m[:title].as('meeting_title'),
        m[:project_id].as('project_id')
      ]
    end
  end

  def self.format_event(event, event_data)
    if event_data['meeting_content_type']
      event.event_title = self.event_meeting_content_title event_data
      event.event_type = event_data['meeting_content_type'].underscore.dasherize
      event.event_path = self.event_path event_data['meeting_id']
      event.event_url = self.event_url event_data['meeting_id']
    else
      event.event_title = self.event_meeting_title event_data
      event.event_path = self.event_path event_data['journable_id']
      event.event_url = self.event_url event_data['journable_id']
    end

    event
  end

  private

  def self.event_meeting_content_title(event)
    "#{event['meeting_content_type'].constantize.model_name.human}: #{event['meeting_title']}"
  end

  def self.event_meeting_title(event)
    start_time = event['meeting_start_time'].is_a?(String) ? DateTime.parse(event['meeting_start_time'])
                                                   : start_time
    end_time = start_time + event['meeting_duration'].to_f.hours

    "#{l :label_meeting}: #{event['meeting_title']} (#{format_date start_time} \
    #{format_time start_time, false}-#{format_time end_time, false})"
  end

  def self.event_path(id)
    Rails.application.routes.url_helpers.meetings_path(id)
  end

  def self.event_url(id)
    Rails.application.routes.url_helpers.meetings_url(id, host: ::Setting.host_name)
  end

  def self.url_helper_parameter(event)
    [  ]
  end
end
