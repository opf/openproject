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
      class ItemsController < ApplicationController
        include OpTurbo::ComponentStream
        include OpTurbo::DialogStreamHelper

        layout "admin"

        model_object CustomField

        before_action :require_admin
        before_action :find_model_object, except: %i[destroy deletion_dialog]
        before_action :find_custom_field_and_item, only: %i[destroy deletion_dialog]

        menu_item :custom_fields

        def index; end

        def new
          update_via_turbo_stream(component: ItemsComponent.new(custom_field: @custom_field,
                                                                new_item_form_data: { show: true }))
          respond_with_turbo_streams
        end

        def create
          ::CustomFields::Hierarchy::HierarchicalItemService
            .new
            .insert_item(**item_input)
            .either(
              ->(_) { update_via_turbo_stream(component: ItemsComponent.new(custom_field: @custom_field)) },
              ->(validation_result) { add_errors_to_form(validation_result) }
            )

          respond_with_turbo_streams
        end

        def destroy
          ::CustomFields::Hierarchy::HierarchicalItemService
            .new
            .delete_branch(item: @hierarchy_item)
            .either(
              ->(_) { update_via_turbo_stream(component: ItemsComponent.new(custom_field: @custom_field)) },
              ->(errors) { update_flash_message_via_turbo_stream(message: errors.full_messages, scheme: :danger) }
            )

          respond_with_turbo_streams
        end

        def deletion_dialog
          respond_with_dialog DeleteItemDialogComponent.new(custom_field: @custom_field,
                                                            hierarchy_item: @hierarchy_item)
        end

        private

        def item_input
          input = { parent: @custom_field.hierarchy_root, label: params[:label] }
          input[:short] = params[:short] unless params[:short].empty?

          input
        end

        def add_errors_to_form(validation_result)
          validation_result.errors(full: true).to_h.each do |attribute, errors|
            @custom_field.errors.add(attribute, errors.join(", "))
          end

          new_item_form_data = { show: true, label: validation_result[:label], short: validation_result[:short] }
          update_via_turbo_stream(component: ItemsComponent.new(custom_field: @custom_field, new_item_form_data:),
                                  status: :unprocessable_entity)
        end

        def find_model_object(object_id = :custom_field_id)
          super
          @custom_field = @object
        end

        def find_custom_field_and_item
          @custom_field = CustomField.find(params[:custom_field_id])
          @hierarchy_item = CustomField::Hierarchy::Item.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render_404
        end
      end
    end
  end
end
