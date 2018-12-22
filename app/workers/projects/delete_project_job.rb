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

module Projects
  class DeleteProjectJob < ApplicationJob
    include OpenProject::LocaleHelper

    attr_reader :user_id,
                :project_id

    def initialize(user_id:, project_id:)
      @user_id = user_id
      @project_id = project_id
    end

    def perform
      service = ::Projects::DeleteProjectService.new(user: user, project: project)
      call = service.call(delayed: false)

      if call.failure?
        logger.error("Failed to delete project #{project} in background job: #{call.errors.join("\n")}")
      end
    rescue StandardError => e
      logger.error('Encountered an error when trying to delete project '\
                   "'#{project_id}' : #{e.message} #{e.backtrace.join("\n")}")
    end

    private

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
