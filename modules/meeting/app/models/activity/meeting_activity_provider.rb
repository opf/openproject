#-- encoding: UTF-8
#-- copyright
# OpenProject Meeting Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
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

class Activity::MeetingActivityProvider < Activity::BaseActivityProvider
  acts_as_activity_provider type: 'meetings',
                            activities: [:meeting, :meeting_content],
                            permission: :view_meetings

  def extend_event_query(query, activity)
    case activity
    when :meeting_content
      query.join(meetings_table).on(activity_journals_table(activity)[:meeting_id].eq(meetings_table[:id]))
      join_cond = journal_table[:journable_type].eq('MeetingContent')
      query.join(meeting_contents_table).on(journal_table[:journable_id].eq(meeting_contents_table[:id]).and(join_cond))
    end
  end

  def event_query_projection(activity)
    case activity
    when :meeting
      [
        activity_journal_projection_statement(:title, 'meeting_title', activity),
        activity_journal_projection_statement(:start_time, 'meeting_start_time', activity),
        activity_journal_projection_statement(:duration, 'meeting_duration', activity),
        activity_journal_projection_statement(:project_id, 'project_id', activity)
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

  def activitied_type(activity)
    (activity == :meeting) ? Meeting : MeetingContent
  end

  def projects_reference_table(activity)
    case activity
    when :meeting
      activity_journals_table(activity)
    else
      meetings_table
    end
  end

  def activity_journals_table(activity)
    case activity
    when :meeting
      @activity_journals_table = JournalManager.journal_class(Meeting).arel_table
    else
      @activity_journals_table = JournalManager.journal_class(MeetingContent).arel_table
    end
  end

  protected

  def event_name(event, activity)
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

  def event_title(event, activity)
    case activity
    when :meeting
      start_time = event['meeting_start_time'].is_a?(String) ? DateTime.parse(event['meeting_start_time'])
                                                             : event['meeting_start_time']
      end_time = start_time + event['meeting_duration'].to_f.hours

      "#{l :label_meeting}: #{event['meeting_title']} (#{format_date start_time} #{format_time start_time, false}-#{format_time end_time, false})"
    else
      "#{event['meeting_content_type'].constantize.model_name.human}: #{event['meeting_title']}"
    end
  end

  def event_type(event, activity)
    case activity
    when :meeting
      'meeting'
    else
      (event['meeting_content_type'].include?('Agenda')) ? 'meeting-agenda' : 'meeting-minutes'
    end
  end

  def event_path(event, activity)
    id = activity_id(event, activity)

    url_helpers.meeting_path(id)
  end

  def event_url(event, activity)
    id = activity_id(event, activity)

    url_helpers.meeting_url(id)
  end

  private

  def meetings_table
    @meetings_table ||= Meeting.arel_table
  end

  def meeting_contents_table
    @meeting_contents_table ||= MeetingContent.arel_table
  end

  def activity_id(event, activity)
    (activity == :meeting) ? event['journable_id'] : event['meeting_id']
  end
end
