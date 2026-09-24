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
      class ItemFormComponent < ApplicationComponent
        include OpTurbo::Streamable

        def item_options
          {
            url:,
            method: http_verb,
            data: {
              turbo_frame: ItemsComponent.wrapper_key,
              test_selector: "op-custom-fields--new-item-form"
            }
          }
        end

        def http_verb
          new_record? ? :post : :put
        end

        def secondary_input_format
          field_format = root.custom_field.field_format
          case field_format
          when "hierarchy"
            :short
          when "weighted_item_list"
            :weight
          when "list"
            nil
          else
            raise ArgumentError, "Unsupported field format: #{field_format}"
          end
        end

        private

        def root
          @root ||= new_record? ? model.parent.root : model.root
        end

        def project_custom_field_context?
          root.custom_field.is_a?(ProjectCustomField)
        end

        def user_custom_field_context?
          root.custom_field.is_a?(UserCustomField)
        end

        def new_record? = model.new_record?

        def custom_field_id = root.custom_field_id

        def url # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
          parent = model.parent
          position = model.sort_order
          if project_custom_field_context?
            if new_record?
              new_child_admin_settings_project_custom_field_item_path(custom_field_id, parent, position:)
            else
              admin_settings_project_custom_field_item_path(custom_field_id, model)
            end
          elsif user_custom_field_context?
            if new_record?
              new_child_admin_settings_user_custom_field_item_path(custom_field_id, parent, position:)
            else
              admin_settings_user_custom_field_item_path(custom_field_id, model)
            end
          elsif new_record?
            new_child_custom_field_item_path(custom_field_id, parent, position:)
          else
            custom_field_item_path(custom_field_id, model)
          end
        end
      end
    end
  end
end
