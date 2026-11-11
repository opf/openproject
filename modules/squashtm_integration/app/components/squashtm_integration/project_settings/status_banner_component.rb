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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module SquashTMIntegration
  module ProjectSettings
    class StatusBannerComponent < ApplicationComponent
      # @param server [SquashTMIntegration::Server, nil] The SquashTM server configured in OpenProject.
      # @param project_link [SquashTMIntegration::ProjectLink] The link between this OpenProject project and a SquashTM
      #   project.
      # @param squashtm_projects [Array<Hash>, nil] The projects fetched from SquashTM (+id+ and +name+) that the
      #   configured access token can see, or nil if SquashTM is not available.
      def initialize(server:, project_link:, squashtm_projects:)
        super()
        @server = server
        @project_link = project_link
        @squashtm_projects = squashtm_projects
      end

      # Whether there is anything to report. Renders nothing while the link is healthy.
      def render?
        state.present?
      end

      private

      # @return [Symbol, nil] The first problem found, in this order: no server configured in OpenProject, SquashTM
      #   unreachable (no project list), or the linked project missing from SquashTM's list.
      def state
        if @server.nil?
          :server_not_configured
        elsif @squashtm_projects.nil?
          :projects_unavailable
        elsif linked_project_missing_in_squashtm?
          :linked_project_missing
        end
      end

      # Compares against the stored id, since a failed update leaves the rejected project in memory. The list only holds
      # the projects visible to the SquashTM account of OpenProject, so this is also true after that account lost access.
      def linked_project_missing_in_squashtm?
        @project_link.persisted? && @squashtm_projects.pluck(:id).exclude?(@project_link.stored_squashtm_project_id)
      end
    end
  end
end
