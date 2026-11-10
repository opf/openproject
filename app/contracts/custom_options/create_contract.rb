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

module CustomOptions
  class CreateContract < ::ModelContract
    include RequiresAdminGuard

    attribute :custom_field_id do
      errors.add(:custom_field, :blank) if model.custom_field.nil?
    end
    attribute :value
    attribute :position
    attribute :default_value
    attribute :project_id do
      validate_additional_project_values_allowed
    end

    private

    def validate_additional_project_values_allowed
      return if model.project_id.nil? || model.custom_field.nil?

      unless model.custom_field.allow_additional_project_values
        errors.add(:project_id, :additional_values_not_allowed)
      end
    end
  end
end
