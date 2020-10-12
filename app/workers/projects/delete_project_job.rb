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

module Projects
  class DeleteProjectJob < ApplicationJob
    queue_with_priority :low
    include OpenProject::LocaleHelper

    attr_reader :user_id,
                :project_id

    def perform(user_id:, project_id:)
      @user_id = user_id
      @project_id = project_id

      service_call = delete_project

      if service_call.failure?
        log_service_failure(service_call)
      end
    rescue StandardError => e
      log_standard_error(e)
    end

    private

    def delete_project
      ::Projects::DeleteService
        .new(user: user, model: project)
        .call
    end

    def log_standard_error(e)
      logger.error('Encountered an error when trying to delete project '\
                   "'#{project_id}' : #{e.message} #{e.backtrace.join("\n")}")
    end

    def log_service_failure(service_call)
      logger.error("Failed to delete project #{project} in background job: #{service_call.errors.join("\n")}")
    end

    def user
      @user ||= User.find user_id
    end

    def project
      @project ||= Project.find project_id
    end

    def logger
      Delayed::Worker.logger
    end
  end
end
