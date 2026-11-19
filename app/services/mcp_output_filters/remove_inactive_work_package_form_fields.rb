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

module McpOutputFilters
  class RemoveInactiveWorkPackageFormFields < HashFilter
    # The form configuration has a single `date` entry, shown as the date picker,
    # which edits these schema properties.
    DATE_PICKER_FIELDS = %w[startDate dueDate duration scheduleManually ignoreNonWorkingDays].freeze

    private

    def on_hash(hash)
      attribute_groups = hash.delete("_attributeGroups")
      return true unless attribute_groups.is_a?(Array)

      hash.except!(*(removable_fields - fields_in_form(attribute_groups)))

      false
    end

    def removable_fields
      configurable_fields | DATE_PICKER_FIELDS
    end

    def fields_in_form(attribute_groups)
      fields = attribute_groups.flat_map { |group| Array(group["attributes"]) }

      fields.include?("date") ? fields | DATE_PICKER_FIELDS : fields
    end

    def configurable_fields
      TypeVariant
        .all_work_package_form_attributes
        .keys
        .map { |name| API::Utilities::PropertyNameConverter.from_ar_name(name) }
    end
  end
end
