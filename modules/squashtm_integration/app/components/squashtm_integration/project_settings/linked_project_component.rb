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
    class LinkedProjectComponent < ApplicationComponent
      def initialize(project:, project_link:, server:)
        super()
        @project = project
        @project_link = project_link
        @server = server
      end

      private

      # This function does its best to provide a Primer::Beta::Link to the SquashTM project. If there is no server
      # is configured, it falls back to the plain text name.
      def project_link_or_name
        name = @project_link.stored_squashtm_project_name
        return name if @server.nil?

        render(Primer::Beta::Link.new(
                 href: Client.for(@server).project_url(@project_link.stored_squashtm_project_id),
                 target: "_blank",
                 rel: "noopener noreferrer",
                 data: { allow_external_link: true }
               )) do |link|
          link.with_trailing_visual_icon(icon: :"link-external")
          name
        end
      end
    end
  end
end
