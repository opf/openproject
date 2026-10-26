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

#
module CustomFields
  class DetailsComponent < ApplicationComponent
    include ApplicationHelper
    include EnterpriseHelper
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    ENTERPRISE_GUARDED = {
      "calculated_value" => { key: :calculated_values, image: "enterprise/calculated-values.png" },
      "hierarchy" => { key: :custom_field_hierarchies, image: "enterprise/hierarchies.png" },
      "weighted_item_list" => { key: :weighted_item_lists, image: "enterprise/weighted_item_lists.png" }
    }.freeze

    alias_method :custom_field, :model

    def initialize(model = nil, form_url:, **)
      super(model, **)
      @form_url = form_url
    end

    attr_reader :form_url

    def form_method
      model.new_record? ? :post : :put
    end

    def confirm_changing_project_specific_values?
      custom_field.persisted? && saved_project_specific_values_mode.present?
    end

    def form_row_arguments
      return {} unless confirm_changing_project_specific_values?

      { data: { controller: "input-confirmation", input_confirmation_trigger_value: "checked" } }
    end

    def change_project_specific_values_dialogs
      target_modes = %w[all allow block] - [saved_project_specific_values_mode]

      safe_join(target_modes.map { |mode| change_project_specific_values_dialog(mode) })
    end

    def change_project_specific_values_dialog(mode)
      scope = "custom_fields.project_specific_values.change"
      direction = "#{saved_project_specific_values_mode}_to_#{mode}"

      render(
        Primer::OpenProject::DangerDialog.new(
          id: CustomFields::DetailsForm.mode_change_dialog_id(saved_project_specific_values_mode, mode),
          title: t("#{direction}.title", scope:),
          confirm_button_text: t("button", scope:),
          cancel_button_text: t(:button_close),
          data: { input_confirmation_target: "dialog" }
        )
      ) do |dialog|
        dialog.with_confirmation_message do |message|
          message.with_heading(tag: :h2) { t("#{direction}.title", scope:) }
          message.with_description_content(t("#{direction}.description", scope:))
        end
        dialog.with_confirmation_check_box_content(t("confirmation", scope:))
      end
    end

    def saved_project_specific_values_mode
      custom_field.project_specific_value_restriction_in_database
    end

    def enterprise_addon_key
      ENTERPRISE_GUARDED.dig(custom_field.field_format, :key)
    end

    def enterprise_addon_image
      ENTERPRISE_GUARDED.dig(custom_field.field_format, :image)
    end

    def no_enterprise_feature?
      ENTERPRISE_GUARDED[custom_field.field_format].nil?
    end

    def show_top_banner?
      case custom_field.field_format
      when "hierarchy", "weighted_item_list", "list"
        persisted_cf_has_no_items_or_projects?
      else
        false
      end
    end

    def top_banner_text
      case custom_field.field_format
      when "hierarchy", "weighted_item_list", "list"
        I18n.t("custom_fields.admin.notice.remember_items_and_projects")
      end
    end

    def persisted_cf_has_no_items_or_projects?
      return false unless custom_field.persisted?
      return false unless custom_field_in_no_project?

      custom_field_has_no_items?
    end

    private

    def custom_field_in_no_project?
      if custom_field.is_a?(WorkPackageCustomField)
        WorkPackageCustomField
          .on_visible_type_and_project(projects: Project.active)
          .where(id: custom_field.id)
          .none?
      elsif custom_field.respond_to?(:projects)
        custom_field.projects.empty?
      else
        true
      end
    end

    def custom_field_has_no_items?
      if custom_field.list?
        custom_field.custom_options.empty?
      elsif custom_field.hierarchical_list?
        custom_field.hierarchy_root.children.empty?
      else
        false
      end
    end
  end
end
