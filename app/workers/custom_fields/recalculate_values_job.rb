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
  class RecalculateValuesJob < ApplicationJob
    include JobConcurrency

    queue_with_priority :default

    good_job_control_concurrency_with(
      total_limit: 1,
      key: -> { "CustomFieldRecalculateValuesJob-#{arguments.first}" }
    )

    def perform(user:, custom_field_id:)
      custom_field = CustomField.find_by(id: custom_field_id)
      return unless custom_field&.field_format_calculated_value?

      User.execute_as(user) { recalculate_values(custom_field) }
    end

    private

    def recalculate_values(custom_field)
      customized_class = custom_field.class.customized_class

      customized_class.find_each do |customized|
        affected_cfs = customized.available_custom_fields.affected_calculated_fields([custom_field.id])

        customized.calculate_custom_fields(affected_cfs)
        customized.save if customized.changed_for_autosave?
      end
    end
  end
end
