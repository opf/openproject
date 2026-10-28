# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

module AI
  module Assistance
    # What the model gets to know about a work package, for one user: its project, the
    # work package, its descendants and relations, its comments, and the agendas of the
    # meetings that discuss it. Only what that user can see; internal comments only with
    # the permission to view them.
    class WorkPackageContext
      MAX_COMMENTS = 30
      MAX_TEXT = 4_000
      MAX_MEETINGS = 10
      MAX_AGENDA_ITEMS = 30
      MAX_AGENDA_TEXT = 1_000

      attr_reader :work_package, :user

      def initialize(work_package:, user:)
        @work_package = work_package
        @user = user
      end

      def to_h
        {
          project: { id: work_package.project.id, name: work_package.project.name,
                     identifier: work_package.project.identifier },
          work_package: work_package_data,
          descendants: descendants_data,
          relations: relations_data,
          pull_requests: pull_requests_data,
          comments: comments_data,
          meetings: meetings_data
        }
      end

      private

      def visibility
        @visibility ||= AI::Assistance::Visibility.new(work_package:, user:)
      end

      def work_package_data
        work_package_fields.merge(work_package_state, work_package_people, work_package_dates)
      end

      def work_package_fields
        {
          id: work_package.formatted_id,
          type: work_package.type&.name,
          subject: work_package.subject,
          description: work_package.description.to_s.truncate(MAX_TEXT * 3)
        }
      end

      def work_package_state
        {
          status: work_package.status&.name,
          default_status: work_package.status&.is_default? || false,
          closed: work_package.closed?
        }
      end

      def work_package_people
        {
          priority: work_package.priority&.name,
          assignee: work_package.assigned_to&.name,
          responsible: work_package.responsible&.name
        }
      end

      def work_package_dates
        {
          start_date: work_package.start_date,
          due_date: work_package.due_date,
          last_activity_at: visibility.last_activity_at&.iso8601
        }
      end

      def descendants_data
        visibility.descendants.map do |descendant|
          { id: descendant.formatted_id, subject: descendant.subject, parent_id: descendant.parent&.formatted_id,
            status: descendant.status&.name, closed: descendant.closed?, updated_at: descendant.updated_at&.iso8601 }
        end
      end

      def relations_data
        visibility.relations.map do |type, other|
          { relation: type, id: other.formatted_id, subject: other.subject, status: other.status&.name,
            closed: other.closed? }
        end
      end

      def pull_requests_data
        visibility.linked_pull_requests.map do |pull_request|
          { repository: pull_request.repository, number: pull_request.number, title: pull_request.title,
            state: pull_request.state }
        end
      end

      # The newest meetings, visible to the user, with this work package on the agenda or
      # in an outcome. Each agenda in full, so the model sees decisions in their context.
      def meetings_data
        return [] unless defined?(::Meeting)

        meetings = related_meetings
        visible_ids = visible_agenda_work_package_ids(meetings)
        meetings.map { |meeting| meeting_data(meeting, visible_ids) }
      end

      def related_meetings
        ::Meeting.visible(user).not_templated.where(id: related_meeting_ids)
                 .reorder(start_time: :desc).limit(MAX_MEETINGS)
                 .includes(sections: { agenda_items: %i[outcomes work_package] })
                 .to_a
      end

      def meeting_data(meeting, visible_ids)
        items = meeting.sections.sort_by(&:position).flat_map(&:agenda_items).first(MAX_AGENDA_ITEMS)
        { title: meeting.title, start_time: meeting.start_time&.iso8601, state: meeting.state,
          agenda: items.map { |item| agenda_item_data(item, visible_ids) } }
      end

      def related_meeting_ids
        on_agenda = ::MeetingAgendaItem.where(work_package_id: work_package.id).pluck(:meeting_id)
        in_outcome = ::MeetingAgendaItem.joins(:outcomes)
                                       .where(meeting_outcomes: { work_package_id: work_package.id })
                                       .pluck(:meeting_id)
        (on_agenda + in_outcome).uniq
      end

      # An agenda item about another work package names it only when the user can see it.
      def visible_agenda_work_package_ids(meetings)
        ids = meetings.flat_map { |m| m.sections.flat_map(&:agenda_items) }.filter_map(&:work_package_id)
        WorkPackage.visible(user).where(id: ids).pluck(:id).to_set
      end

      def agenda_item_data(item, visible_ids)
        {
          title: agenda_item_title(item, visible_ids),
          about_this_work_package: item.work_package_id == work_package.id,
          notes: item.notes.to_s.truncate(MAX_AGENDA_TEXT).presence,
          outcomes: item.outcomes.filter_map { |outcome| outcome.notes.to_s.truncate(MAX_AGENDA_TEXT).presence }.presence
        }.compact
      end

      def agenda_item_title(item, visible_ids)
        return item.title if item.work_package_id.nil?
        return "(work package not visible)" unless visible_ids.include?(item.work_package_id)

        "#{item.work_package.formatted_id} #{item.work_package.subject}"
      end

      def comments_data
        recent_comments.map do |journal|
          { author: journal.user&.name, at: journal.created_at.iso8601,
            internal: journal.internal?, text: journal.notes.truncate(MAX_TEXT) }
        end
      end

      # The jobs run as the user, so User.current is the user here.
      def recent_comments
        work_package.journals.internal_visible.where.not(notes: [nil, ""])
                    .includes(:user)
                    .reorder(created_at: :desc)
                    .limit(MAX_COMMENTS)
                    .reverse
      end
    end
  end
end
