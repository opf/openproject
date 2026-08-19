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

class Workflows::Copies::Form < ApplicationForm
  def initialize(source_type:, source_role:, other_types:, all_roles:, append_to: nil)
    super()
    @source_type = source_type
    @source_role = source_role
    @other_types = other_types
    @all_roles = all_roles
    @append_to = append_to
  end

  form do |copy|
    another_type_at_first = @source_role.nil?
    copy.advanced_radio_button_group(name: :mode) do |radio_group|
      radio_group.radio_button(
        value: "from_type",
        checked: another_type_at_first,
        label: helpers.t("workflows.copies.form.mode.from_type.label"),
        caption: helpers.t("workflows.copies.form.mode.from_type.caption"),
        data: {
          target_name: "mode",
          "show-when-value-selected-target": "cause"
        }
      )
      radio_group.radio_button(
        value: "from_role",
        checked: !another_type_at_first,
        label: helpers.t("workflows.copies.form.mode.from_role.label"),
        caption: helpers.t("workflows.copies.form.mode.from_role.caption"),
        data: {
          target_name: "mode",
          "show-when-value-selected-target": "cause"
        }
      )
    end

    copy.group(
      hidden: !another_type_at_first,
      data: {
        target_name: "mode",
        value: "from_type",
        "show-when-value-selected-target": "effect"
      }
    ) do |from_type|
      from_type.autocompleter(
        name: "target_type_ids",
        required: true,
        include_blank: false,
        label: helpers.t("workflows.copies.form.target_type_ids.label"),
        autocomplete_options: {
          multiple: true,
          decorated: true,
          closeOnSelect: false,
          appendTo: @append_to,
          dropdownPosition: "top",
          data: {
            "test-selector": "target_types_autocomplete"
          }
        }
      ) do |target_list|
        @other_types.each do |other_type|
          target_list.option(label: other_type.name, value: other_type.id)
        end
      end
    end

    copy.group(
      hidden: another_type_at_first,
      data: {
        target_name: "mode",
        value: "from_role",
        "show-when-value-selected-target": "effect"
      }
    ) do |from_role|
      source_label = helpers.t("workflows.copies.form.source_role_id.label")
      required = another_type_at_first
      disabled = !another_type_at_first
      from_role.select_list(name: :source_role_id, label: source_label, required:, disabled:) do |source_role_list|
        @all_roles.each do |role|
          source_role_list.option(label: role.name, value: role.id, selected: role == @source_role)
        end
      end
      from_role.autocompleter(
        name: "target_role_ids",
        required: true,
        include_blank: false,
        label: helpers.t("workflows.copies.form.target_role_ids.label"),
        autocomplete_options: {
          multiple: true,
          decorated: true,
          closeOnSelect: false,
          dropdownPosition: "top",
          appendTo: @append_to,
          data: {
            "test-selector": "target_roles_autocomplete"
          }
        }
      ) do |target_list|
        @all_roles.each do |role|
          target_list.option(label: role.name, value: role.id)
        end
      end
    end
  end
end
