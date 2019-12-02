#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

module Bcf::API::V2_1
  module ProjectExtensions
    class Definitions
      def initialize(project:, user:)
        @project = project
        @user = user
      end

      def topic_type
        with_manage_bcf do
          contract.assignable_types.pluck(:name)
        end
      end

      ##
      # We only return the default status for now
      # since that can always be set to a new issue
      def topic_status
        with_manage_bcf do
          contract.assignable_statuses(true).pluck(:name)
        end
      end

      def priority
        with_manage_bcf do
          contract.assignable_priorities.pluck(:name)
        end
      end

      def user_id_type
        with_manage_bcf do
          if allowed?(:view_members)
            # TODO: Move possible_assignees handling into wp base contract
            project.possible_assignees.pluck(:mail)
          else
            []
          end
        end
      end

      # TODO: Labels do not yet exist
      def topic_label
        []
      end

      # TODO: Stage do not yet exist
      def stage
        []
      end

      # TODO: Snippet types do not exist
      def snippet_type
        []
      end

      def project_actions
        [].tap do |actions|
          actions << 'update' if allowed?(:edit_project)
          actions << 'createTopic' if allowed?(:manage_bcf)
        end
      end

      def topic_actions
        with_manage_bcf do
          %w[update updateRelatedTopics updateFiles createViewpoint]
        end
      end

      def comment_actions
        []
      end

      def contract
        @contract ||= begin
          work_package = WorkPackage.new project: project
          WorkPackages::CreateContract.new(work_package, user)
        end
      end

      private

      attr_reader :user, :project

      def with_manage_bcf
        if allowed?(:manage_bcf)
          yield
        else
          []
        end
      end

      def allowed?(permission)
        user.allowed_to?(permission, project)
      end
    end
  end
end
