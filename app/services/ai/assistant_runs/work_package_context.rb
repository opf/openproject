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
  module AssistantRuns
    # What the model gets to know about a work package, for one user: the work package,
    # its descendants and relations, and its comments. Only what that user can see;
    # internal comments only with the permission to view them.
    class WorkPackageContext
      MAX_COMMENTS = 30
      MAX_TEXT = 4_000

      attr_reader :work_package, :user

      def initialize(work_package:, user:)
        @work_package = work_package
        @user = user
      end

      def to_h
        {
          work_package: work_package_data,
          descendants: descendants_data,
          relations: relations_data,
          comments: comments_data
        }
      end

      private

      def visibility
        @visibility ||= AI::AssistantSkills::HealthCheck::Context.new(work_package:, user:)
      end

      def work_package_data
        {
          id: work_package.formatted_id,
          type: work_package.type&.name,
          status: work_package.status&.name,
          closed: work_package.closed?,
          subject: work_package.subject,
          description: work_package.description.to_s.truncate(MAX_TEXT * 3),
          start_date: work_package.start_date,
          due_date: work_package.due_date,
          priority: work_package.priority&.name,
          assignee: work_package.assigned_to&.name
        }
      end

      def descendants_data
        visibility.descendants.map do |descendant|
          { id: descendant.formatted_id, subject: descendant.subject,
            status: descendant.status&.name, closed: descendant.closed? }
        end
      end

      def relations_data
        visibility.relations.map do |type, other|
          { relation: type, id: other.formatted_id, subject: other.subject, status: other.status&.name }
        end
      end

      # The rule of WorkPackage#journals.internal_visible, for this user instead of
      # User.current: a job may run without that user's request.
      def visible_journals
        project = work_package.project
        if EnterpriseToken.allows_to?(:internal_comments) &&
           project.enabled_internal_comments &&
           user.allowed_in_project?(:view_internal_comments, project)
          work_package.journals
        else
          work_package.journals.where(internal: false)
        end
      end

      def comments_data
        visible_journals.where.not(notes: [nil, ""])
                        .includes(:user)
                        .reorder(created_at: :desc)
                        .limit(MAX_COMMENTS)
                        .reverse
                        .map do |journal|
          { author: journal.user&.name, at: journal.created_at.iso8601,
            internal: journal.internal?, text: journal.notes.truncate(MAX_TEXT) }
        end
      end
    end
  end
end
