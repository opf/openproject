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

module Admin
  module Settings
    # Shared behaviour for the dedicated per-type custom field admin pages
    class CustomFieldsBaseController < ::Admin::SettingsController
      include ::CustomFields::SharedActions
      include ::CustomFields::AttributeHelpTextActions

      # rubocop:disable Rails/LexicallyScopedActionFilter
      before_action :find_custom_field,
                    only: %i(edit update destroy delete_option reorder_alphabetical attribute_help_text
                             update_attribute_help_text list_items)
      before_action :prepare_custom_option_position, only: %i(update create)
      before_action :find_custom_option, only: :delete_option
      before_action :validate_enterprise_token, only: %i(create)
      before_action :find_or_initialize_attribute_help_text, only: %i(attribute_help_text update_attribute_help_text)
      # rubocop:enable Rails/LexicallyScopedActionFilter

      helper_method :index_path, :new_path, :edit_path, :member_path, :delete_option_path, :list_item_path,
                    :reorder_alphabetical_path, :attribute_help_text_path, :update_attribute_help_text_path,
                    :items_path, :projects_path, :custom_field_page_title, :section_label, :customizable_name

      def index
        @custom_fields = custom_field_scope
      end

      def new
        @custom_field = new_custom_field
      end

      def edit; end

      def list_items; end

      def attribute_help_text
        render_attribute_help_text_form
      end

      def update_attribute_help_text
        update_help_text
      end

      protected

      def custom_field_class
        raise SubclassResponsibilityError, "#{self.class} must implement #custom_field_class"
      end

      def custom_field_page_title
        raise SubclassResponsibilityError, "#{self.class} must implement #custom_field_page_title"
      end

      def section_label
        raise SubclassResponsibilityError, "#{self.class} must implement #section_label"
      end

      def index_path(*, **params)
        url_for(only_path: true, action: :index, **params)
      end

      def new_path(field_format: nil)
        url_for(only_path: true, action: :new, field_format:)
      end

      def edit_path(custom_field, *, **)
        url_for(only_path: true, action: :edit, id: custom_field)
      end

      def member_path(custom_field)
        url_for(only_path: true, action: :show, id: custom_field)
      end

      def delete_option_path(custom_field, custom_option)
        url_for(only_path: true, action: :delete_option, id: custom_field.id || 0, option_id: custom_option.id || 0)
      end

      def list_item_path(custom_field, *, **)
        url_for(only_path: true, action: :list_items, id: custom_field)
      end

      def reorder_alphabetical_path(custom_field)
        url_for(only_path: true, action: :reorder_alphabetical, id: custom_field)
      end

      def attribute_help_text_path(custom_field)
        url_for(only_path: true, action: :attribute_help_text, id: custom_field)
      end

      def update_attribute_help_text_path(custom_field)
        url_for(only_path: true, action: :update_attribute_help_text, id: custom_field)
      end

      # Hierarchy items and project mappings stay on the shared global routes
      def items_path(custom_field)
        custom_field_items_path(custom_field)
      end

      def projects_path(custom_field)
        custom_field_projects_path(custom_field)
      end

      def customizable_name
        custom_field_class.name.delete_suffix("CustomField")
      end

      def custom_field_scope
        custom_field_class.all
      end

      def new_custom_field
        custom_field_class.new(field_format: params[:field_format])
      end

      def find_custom_field
        @custom_field = custom_field_class.find(params.expect(:id))
      end

      def validate_enterprise_token
        if params.dig(:custom_field, :field_format) == "hierarchy" && !EnterpriseToken.allows_to?(:custom_field_hierarchies)
          render_403
        end
      end

      def show_path
        attribute_help_text_path(@custom_field)
      end

      def render_attribute_help_text_form(status: :ok)
        render "custom_fields/attribute_help_texts/show_work_package", status:
      end
    end
  end
end
