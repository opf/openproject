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

module AuthorizesProjectValueManagement
  extend ActiveSupport::Concern

  included do
    validate :validate_may_manage_value
  end

  def validate_may_manage_value
    return if user.active_admin?
    return if project_value_manageable?

    errors.add :base, :error_unauthorized
  end

  private

  def validate_additional_values_allowed
    return if model.project_id.nil? || custom_field.nil? || custom_field.allow_additional_project_values

    errors.add(:project_id, :additional_values_not_allowed)
  end

  def project_value_manageable?
    project_value_permitted? && custom_field&.allow_additional_project_values?
  end

  def project_value_permitted?
    model.project_id.present? && user.allowed_in_project?(:manage_work_package_custom_field_values, model.project)
  end
end
