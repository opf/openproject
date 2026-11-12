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

module CustomFields
  class UpdateService < ::BaseServices::Update
    protected

    def after_perform(service_call)
      super.tap do
        enqueue_recalculate_values if recalculate_values?
        reset_project_specific_value_restrictions if model.project_specific_value_restriction_previously_changed?
      end
    end

    def reset_project_specific_value_restrictions
      model.project_specific_value_restrictions.delete_all
      return unless model.project_specific_value_restriction_allow? && model.hierarchical_list?

      projects_with_own_values.find_each do |project|
        ProjectSpecificValues::EnableRequiredValuesService.new(model:).call(project:)
      end
    end

    def projects_with_own_values
      Project.where(id: model.restrictable_values.where.not(project_id: nil).select(:project_id))
    end

    private

    def set_attributes_params(params)
      super.except(:field_format)
    end

    def enqueue_recalculate_values
      CustomFields::RecalculateValuesJob.perform_later(
        user: User.current,
        custom_field_id: model.id
      )
    end

    def recalculate_values?
      case model.field_format
      when "calculated_value"
        model.formula_previously_changed? || (model.is_required_previously_changed? && model.is_required?)
      when "weighted_item_list"
        model.multi_value_previously_changed? && CustomField.with_formula_referencing(model.id).any?
      else
        false
      end
    end
  end
end
