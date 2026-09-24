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
  module CustomFields
    module Hierarchy
      class ItemComponent < ApplicationComponent
        include OpTurbo::Streamable
        include OpPrimer::ComponentHelpers

        class << self
          def menu_id(item:)
            "op-custom-field-hierarchy-item-#{item.id}-action-menu"
          end
        end

        def initialize(item:, custom_field:, show_edit_form: false)
          super(item)
          @show_edit_form = show_edit_form
          @custom_field = custom_field
        end

        def wrapper_uniq_by
          model.id
        end

        def menu_id
          self.class.menu_id(item: model)
        end

        def secondary_text
          ::CustomFields::Hierarchy::HierarchicalItemFormatter
            .new(label: false,
                 number_length_limit: 42,
                 number_integer_digit_limit: 40,
                 number_precision: 40)
            .format(item: model)
        end

        def item_link
          if project_custom_field_context?
            admin_settings_project_custom_field_item_path(custom_field_id, model)
          elsif user_custom_field_context?
            admin_settings_user_custom_field_item_path(custom_field_id, model)
          else
            custom_field_item_path(custom_field_id, model)
          end
        end

        def item_actions_href
          if project_custom_field_context?
            item_actions_admin_settings_project_custom_field_item_path(custom_field_id, model)
          elsif user_custom_field_context?
            item_actions_admin_settings_user_custom_field_item_path(custom_field_id, model)
          else
            item_actions_custom_field_item_path(custom_field_id, model)
          end
        end

        def show_form? = @show_edit_form || model.new_record?

        def children_count
          I18n.t("custom_fields.admin.hierarchy.subitems", count: model.children_count)
        end

        def label_addition = model.suffix

        private

        def project_custom_field_context?
          @project_custom_field_context ||= @custom_field.is_a?(ProjectCustomField)
        end

        def user_custom_field_context?
          @user_custom_field_context ||= @custom_field.is_a?(UserCustomField)
        end

        def custom_field_id = @custom_field.id
      end
    end
  end
end
