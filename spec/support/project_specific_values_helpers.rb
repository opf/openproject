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

module ProjectSpecificValuesHelpers
  def restrict_items_in(project, *items)
    items.each { create(:project_specific_value_restriction, project:, hierarchy_item: it) }
  end

  def insert_project_item(parent:, label:, project:)
    CustomFields::Hierarchy::HierarchicalItemService
      .new
      .insert_item(contract_class: CustomFields::Hierarchy::InsertListItemContract, parent:, label:, project:)
      .value!
  end

  def toggle_project_value(custom_field, project:, value:, enabled:, user:)
    CustomFields::ProjectSpecificValues::SetService
      .new(user:, model: custom_field)
      .call(project:, value:, enabled:)
  end

  def disable_all_project_values(custom_field, project:, user:)
    CustomFields::ProjectSpecificValues::DisableAllService
      .new(user:, model: custom_field)
      .call(project:)
  end

  def switch_project_value_restriction(custom_field, mode, user:)
    CustomFields::UpdateService
      .new(user:, model: custom_field)
      .call(project_specific_value_restriction: mode)
  end
end
