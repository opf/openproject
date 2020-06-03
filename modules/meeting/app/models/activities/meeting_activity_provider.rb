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

class Activities::MeetingActivityProvider < Activities::BaseActivityProvider
  activity_provider_for type: 'meetings',
                        activities: %i[meeting meeting_content],
                        permission: :view_meetings

  def extend_event_query(query)
    case activity
    when :meeting_content
      query.join(meetings_table).on(activity_journals_table[:meeting_id].eq(meetings_table[:id]))
      join_cond = journals_table[:journable_type].eq('MeetingContent')
      query.join(meeting_contents_table).on(journals_table[:journable_id].eq(meeting_contents_table[:id]).and(join_cond))
    else
      super
    end
  end

  def event_query_projection
    case activity
    when :meeting
      [
        activity_journal_projection_statement(:title, 'meeting_title'),
        activity_journal_projection_statement(:start_time, 'meeting_start_time'),
        activity_journal_projection_statement(:duration, 'meeting_duration'),
        activity_journal_projection_statement(:project_id, 'project_id')
      ]
    else
      [
        projection_statement(meeting_contents_table, :type, 'meeting_content_type'),
        projection_statement(meetings_table, :id, 'meeting_id'),
        projection_statement(meetings_table, :title, 'meeting_title'),
        projection_statement(meetings_table, :project_id, 'project_id')
      ]
    end
  end

  def activitied_type
    activity == :meeting ? Meeting : MeetingContent
  end

  def projects_reference_table
    case activity
    when :meeting
      activity_journals_table
    else
      meetings_table
    end
  end

  def activity_journals_table
    @activity_journals_table ||= case activity
                                 when :meeting
                                   Meeting.journal_class.arel_table
                                 else
                                   MeetingContent.journal_class.arel_table
                                 end
  end

  protected

  def event_name(event)
    case event['event_description']
    when 'Agenda closed'
      I18n.t('meeting_agenda_closed', scope: 'events')
    when 'Agenda opened'
      I18n.t('meeting_agenda_opened', scope: 'events')
    when 'Minutes created'
      I18n.t('meeting_minutes_created', scope: 'events')
    else
      super
    end
  end

  def event_title(event)
    case activity
    when :meeting
      start_time = if event['meeting_start_time'].is_a?(String)
                     DateTime.parse(event['meeting_start_time'])
                   else
                     event['meeting_start_time']
                   end
      end_time = start_time + event['meeting_duration'].to_f.hours

      "#{l :label_meeting}: #{event['meeting_title']} (#{format_date start_time} #{format_time start_time, false}-#{format_time end_time, false})"
    else
      "#{event['meeting_content_type'].constantize.model_name.human}: #{event['meeting_title']}"
    end
  end

  def event_type(event)
    case activity
    when :meeting
      'meeting'
    else
      event['meeting_content_type'].include?('Agenda') ? 'meeting-agenda' : 'meeting-minutes'
    end
  end

  def event_path(event)
    id = activity_id(event)

    url_helpers.meeting_path(id)
  end

  def event_url(event)
    id = activity_id(event)

    url_helpers.meeting_url(id)
  end

  private

  def meetings_table
    @meetings_table ||= Meeting.arel_table
  end

  def meeting_contents_table
    @meeting_contents_table ||= MeetingContent.arel_table
  end

  def activity_id(event)
    activity == :meeting ? event['journable_id'] : event['meeting_id']
  end
end
