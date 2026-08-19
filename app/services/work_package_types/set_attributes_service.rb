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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  class SetAttributesService < ::BaseServices::SetAttributes
    def initialize(user:, model:, contract_class:, contract_options: nil)
      super
      @param_validations = {}
    end

    private

    def set_attributes(params)
      permitted = params.except(:copy_workflow_from)

      check_patterns(permitted)
      check_copy_workflow(params)
      check_projects(permitted)

      super(permitted.except(*@param_validations.keys))
    end

    def validate_and_result
      success, errors = validate(model, user, options: {})

      if @param_validations.empty?
        ServiceResult.new(success:, errors:, result: model)
      else
        @param_validations.each_pair do |key, error|
          errors.add(key, error)
        end

        ServiceResult.failure(errors:, result: model)
      end
    end

    def check_patterns(params)
      return unless params.key?(:patterns)
      return if params.key?(:patterns) && params[:patterns].blank?

      result = WorkPackageTypes::Patterns::CollectionContract.new.call(params[:patterns])
      if result.failure?
        @param_validations.update({ patterns: validation_failure_to_message(result).join(", ") })
      end
    rescue ArgumentError
      @param_validations.update({ patterns: :is_invalid })
    end

    def check_copy_workflow(params)
      return unless params.key?(:copy_workflow_from)

      result = CopyWorkflowAttributeContract.new.call(params.slice(:copy_workflow_from))
      if result.failure?
        @param_validations.update({ copy_workflow_from: validation_failure_to_message(result).join(", ") })
      end
    end

    def check_projects(params)
      return unless params.key?(:project_ids)

      invalid_project_ids = params[:project_ids].reject { |id| id.blank? || Project.exists?(id) }
      unless invalid_project_ids.empty?
        @param_validations.update({ project_ids: "Projects with ids #{invalid_project_ids.join(', ')} do not exist." })
      end
    end

    def validation_failure_to_message(result)
      flatten_error_messages result.errors(full: true).to_h
    end

    def flatten_error_messages(errors)
      case errors
      when String
        [errors]
      when Array
        errors.flat_map { |e| flatten_error_messages(e) }
      when Hash
        errors.values.flat_map { |e| flatten_error_messages(e) }
      else
        []
      end
    end
  end
end
