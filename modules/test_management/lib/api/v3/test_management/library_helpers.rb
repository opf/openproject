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

module API
  module V3
    module TestManagement
      module LibraryHelpers
        FOLDER_ATTRIBUTES = { "name" => :name, "parentId" => :parent_id, "position" => :position }.freeze
        CASE_ATTRIBUTES = {
          "title" => :title,
          "description" => :description,
          "preconditions" => :preconditions,
          "priority" => :priority,
          "status" => :status,
          "automated" => :automated,
          "automationReference" => :automation_reference,
          "folderId" => :suite_id,
          "assigneeId" => :assigned_to_id
        }.freeze

        def folder_attributes
          attributes_from(FOLDER_ATTRIBUTES)
        end

        def case_attributes(test_case = nil)
          attributes = attributes_from(CASE_ATTRIBUTES)
          attributes[:steps_attributes] = step_attributes(request_body["steps"], test_case) if request_body.key?("steps")
          attributes
        end

        def ensure_lock_version!(test_case)
          lock_version = request_body["lockVersion"]
          raise ::API::Errors::UnprocessableContent.new(I18n.t("test_management.api.lock_version_required")) if lock_version.nil?
          return if lock_version.to_i == test_case.lock_version

          raise ::API::Errors::Conflict.new(message: I18n.t("test_management.api.stale_case"))
        end

        private

        def step_attributes(steps, test_case)
          raise ::API::Errors::UnprocessableContent.new("steps must be a list.") unless steps.is_a?(Array)

          removed = test_case ? test_case.steps.map { { "id" => it.id, "_destroy" => "1" } } : []
          added = steps.each_with_index.map do |step, position|
            step = step.to_h.stringify_keys
            { "position" => position, "action" => step["action"], "expected_result" => step["expectedResult"],
              "data" => step["data"] }
          end
          removed + added
        end
      end
    end
  end
end
