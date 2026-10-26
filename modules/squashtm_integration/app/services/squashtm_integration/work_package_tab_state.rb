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
  class WorkPackageTabState
    attr_reader :work_package, :user

    delegate :project, to: :work_package

    def initialize(work_package:, user:)
      @work_package = work_package
      @user = user
    end

    def status
      if server.nil? then :no_server
      elsif project_link.nil? then :project_not_linked
      else :not_linked
      end
    end

    def server
      return @server if defined?(@server)

      @server = Server.first
    end

    def project_link
      return @project_link if defined?(@project_link)

      @project_link = ProjectLink.find_by(project:)
    end

    def can_configure_server?
      user.admin?
    end

    def can_manage_project_link?
      user.allowed_in_project?(:manage_squashtm_integration, project)
    end
  end
end
