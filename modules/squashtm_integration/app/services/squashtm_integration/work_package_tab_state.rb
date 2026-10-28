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
    attr_reader :work_package, :user, :work_package_link

    delegate :project, to: :work_package

    def initialize(work_package:, user:, work_package_link: nil)
      @work_package = work_package
      @user = user
      @work_package_link = work_package_link || WorkPackageLink.find_or_initialize_by(work_package:)
    end

    def status
      if server.nil? then :no_server
      elsif work_package_link.persisted? then :linked
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

    def can_manage_links?
      user.allowed_in_project?(:manage_squashtm_links, project)
    end

    def can_manage_project_link?
      user.allowed_in_project?(:manage_squashtm_integration, project)
    end

    def requirement
      load_requirement unless defined?(@requirement)
      @requirement
    end

    def requirement_error
      requirement
      @requirement_error
    end

    def requirement_options
      load_requirement_options unless defined?(@requirement_options)
      @requirement_options
    end

    private

    def client
      @client ||= Client.for(server)
    end

    def load_requirement
      @requirement = RequirementCoverage.new(client).call(work_package_link.squashtm_requirement_id_in_database)
    rescue Client::NotFoundError
      @requirement = nil
      @requirement_error = :not_found
    rescue Client::Error => e
      log_error("SquashTM requirement #{work_package_link.squashtm_requirement_id_in_database} could not be loaded", e)
      @requirement = nil
      @requirement_error = :unavailable
    end

    def load_requirement_options
      @requirement_options = client.all_requirements(project_link.squashtm_project_id)
                                   .map { it.slice("id", "name").symbolize_keys }
                                   .sort_by { it[:name].to_s.downcase }
    rescue Client::Error => e
      log_error("SquashTM requirements of project #{project_link.squashtm_project_id} could not be loaded", e)
      @requirement_options = nil
    end

    def log_error(message, error)
      Rails.logger.warn("#{message}: #{error.class}: #{error.message}")
    end
  end
end
