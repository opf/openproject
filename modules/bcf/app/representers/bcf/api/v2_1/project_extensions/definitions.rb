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
        project.types.pluck(:name)
      end

      ##
      # We only return the default status for now
      # since that can always be set to a new issue
      def topic_status
        Status
          .where_default
          .pluck(:name)
      end

      def priority
        OpenProject::Cache.fetch(IssuePriority.all.cache_key, 'names') do
          IssuePriority.all.pluck(:name)
        end
      end

      def user_id_type
        if allowed?(:view_members)
          project.possible_assignees.pluck(:mail)
        else
          []
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
        if allowed?(:manage_bcf)
          %w[update updateRelatedTopics updateFiles createViewpoint]
        else
          []
        end
      end

      def comment_actions
        []
      end

      private

      attr_reader :project, :user

      def allowed?(permission)
        user.allowed_to?(permission, project)
      end
    end
  end
end

