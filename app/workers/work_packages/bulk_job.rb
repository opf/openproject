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

module WorkPackages
  class BulkJob < ApplicationJob
    include WorkPackages::BulkErrorMessage
    queue_with_priority :above_normal

    attr_accessor :work_packages, :user, :follow, :project, :target_project

    def perform(user:, work_package_ids:, project:, target_project:, params:, follow:)
      self.project = project
      self.target_project = target_project
      self.user = user
      self.follow = follow
      self.work_packages = WorkPackage.where(id: work_package_ids)

      service_class
        .new(user:, work_packages:)
        .call(params)
        .on_success(&method(:successful_status_update))
        .on_failure(&method(:failure_status_update))
        .then(&method(:wrap_result))
    end

    def store_status?
      true
    end

    def updates_own_status?
      true
    end

    protected

    def wrap_result(call)
      message = call.success? ? success_message : bulk_error_message(work_packages, call)

      ServiceResult.new(
        success: call.success,
        result: redirect_path(call, follow),
        message:,
        dependent_results: [call]
      )
    end

    def service_class
      raise NotImplementedError
    end

    def successful_status_update(call)
      path = redirect_path(call, follow)
      payload = redirect_payload(path)

      upsert_status status: :success,
                    message: success_message,
                    payload:
    end

    def redirect_path(call, follow)
      if follow
        if call.success? && work_packages.size == 1
          url_helpers.work_package_path(call.dependent_results.first.result)
        else
          url_helpers.project_work_packages_path(target_project || project)
        end
      else
        url_helpers.project_work_packages_path(project)
      end
    end

    def failure_status_update(call)
      message = failure_message
      html = bulk_error_message(work_packages, call)

      upsert_status status: :failure,
                    message:,
                    payload: { html: }
    end

    def url_helpers
      @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
    end
  end
end
