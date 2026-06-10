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

module ResourcePlannerViews
  module Forms
    class ConfigureForm < ApplicationForm
      form do |f|
        f.text_field(
          name: :name,
          label: PersistedView.human_attribute_name(:name),
          required: true
        )

        # `filter_mode` is a UI-only toggle (not persisted on the view); the
        # `show-when-value-selected` controller toggles the filter form. The
        # checked radio reflects the persisted query so editing a hand-picked
        # view does not silently revert it to automatic.
        manual = model.respond_to?(:manually_picked?) && model.manually_picked?

        f.advanced_radio_button_group(
          name: :filter_mode,
          label: I18n.t("resource_management.configure_view_dialog.filter_mode.label"),
          visually_hide_label: true,
          scope_name_to_model: false
        ) do |group|
          group.radio_button(
            value: "automatic",
            checked: !manual,
            label: I18n.t("resource_management.configure_view_dialog.filter_mode.automatic.label"),
            caption: I18n.t("resource_management.configure_view_dialog.filter_mode.automatic.caption"),
            data: { target_name: "filter_mode", "show-when-value-selected-target": "cause" }
          )
          group.radio_button(
            value: "manual",
            checked: manual,
            label: I18n.t("resource_management.configure_view_dialog.filter_mode.manual.label"),
            caption: I18n.t("resource_management.configure_view_dialog.filter_mode.manual.caption"),
            data: { target_name: "filter_mode", "show-when-value-selected-target": "cause" }
          )
        end
      end
    end
  end
end
