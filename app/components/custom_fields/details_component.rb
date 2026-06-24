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

    def form_url
      if model.new_record?
        case model.type
        when "ProjectCustomField" then admin_settings_project_custom_fields_path
        when "UserCustomField" then admin_settings_user_custom_fields_path
        else custom_fields_path
        end
      else
        case model.type
        when "ProjectCustomField" then admin_settings_project_custom_field_path(model)
        when "UserCustomField" then admin_settings_user_custom_field_path(model)
        else custom_field_path(model)
        end
      end
    end

    def form_method
      model.new_record? ? :post : :put
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
      return false unless custom_field_has_no_projects?

      custom_field_has_no_items?
    end

    private

    def custom_field_has_no_projects?
      !custom_field.respond_to?(:projects) || custom_field.projects.empty?
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
