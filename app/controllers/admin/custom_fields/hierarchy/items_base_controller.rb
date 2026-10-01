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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin
  module CustomFields
    module Hierarchy
      class ItemsBaseController < ApplicationController
        include OpTurbo::ComponentStream
        include Dry::Monads[:result]

        layout :admin_or_frame_layout

        before_action :require_admin
        before_action :find_custom_field
        before_action :find_active_item

        # See https://github.com/hotwired/turbo-rails?tab=readme-ov-file#a-note-on-custom-layouts
        def admin_or_frame_layout
          return "turbo_rails/frame" if turbo_frame_request?

          "admin"
        end

        def index; end

        def show
          render action: :index
        end

        def new
          @new_item = @active_item.children.build(sort_order: params[:position])
        end

        def edit; end

        def create
          item_service
            .insert_item(contract_class: create_contract, **insert_item_input)
            .either(
              lambda { |item| redirect_to action: :new, position: item.sort_order + 1 },
              lambda do |validation_result|
                add_errors_to_new_form(validation_result)
                render :new
              end
            )
        end

        def update
          item_service
            .update_item(contract_class: update_contract, **update_item_input)
            .either(
              ->(*) { redirect_to action: :show, id: @active_item.parent, status: :see_other },
              lambda do |validation_result|
                add_errors_to_edit_form(validation_result)
                update_via_turbo_stream(
                  component: ItemComponent.new(item: @active_item, custom_field: @custom_field, show_edit_form: true)
                )
                respond_with_turbo_streams
              end
            )
        end

        def move
          item_service
            .reorder_item(item: @active_item, new_sort_order: params.require(:new_sort_order))

          redirect_to action: :show, id: @active_item.parent, status: :see_other
        end

        def change_parent
          parse_parent_input(new_parent_params)
            .bind { item_service.move_item(item: @active_item, new_parent: it) }
            .either(
              ->(result) do
                redirect_to action: :show,
                            id: result.parent,
                            status: :see_other,
                            notice: I18n.t(:notice_successful_update)
              end,
              ->(error) do
                render_error_flash_message_via_turbo_stream(message: error)
                respond_with_turbo_streams(&:html)
              end
            )
        end

        def destroy
          item_service
            .delete_branch(item: @active_item)
            .either(
              ->(_) do
                update_via_turbo_stream(
                  component: ItemsComponent.new(item: @active_item.parent.reload)
                )
              end,
              ->(errors) { render_error_flash_message_via_turbo_stream(message: errors.full_messages) }
            )

          respond_with_turbo_streams(&:html)
        end

        def deletion_dialog
          respond_with_dialog DeleteItemDialogComponent.new(custom_field: @custom_field, hierarchy_item: @active_item)
        end

        def change_parent_dialog
          respond_with_dialog ChangeItemParentDialogComponent.new(
            custom_field: @custom_field,
            hierarchy_item: @active_item
          )
        end

        def item_actions
          render Item::ActionsComponent.new(@active_item), layout: false
        end

        private

        def item_service
          ::CustomFields::Hierarchy::HierarchicalItemService.new
        end

        def insert_item_input
          {
            parent: @active_item,
            label: params[:label],
            short: params[:short],
            weight: params[:weight],
            before: params[:sort_order]
          }
        end

        def update_item_input
          {
            item: @active_item,
            label: params[:label],
            short: params[:short],
            weight: params[:weight]
          }
        end

        def new_parent_params
          params.require(:custom_field_hierarchy_forms_new_parent_form_model).require(:new_parent)
        end

        def create_contract
          case @custom_field.field_format
          when "hierarchy"
            ::CustomFields::Hierarchy::InsertListItemContract
          when "weighted_item_list"
            ::CustomFields::Hierarchy::InsertWeightedItemContract
          else
            raise ArgumentError, "unsupported custom field format '#{@custom_field.field_format}'"
          end
        end

        def update_contract
          case @custom_field.field_format
          when "hierarchy"
            ::CustomFields::Hierarchy::UpdateListItemContract
          when "weighted_item_list"
            ::CustomFields::Hierarchy::UpdateWeightedItemContract
          else
            raise ArgumentError, "unsupported custom field format '#{@custom_field.field_format}'"
          end
        end

        def add_errors_to_new_form(validation_result)
          attributes = insert_item_input
          attributes[:sort_order] = attributes.delete(:before)

          @new_item = ::CustomField::Hierarchy::Item.new(**attributes)
          validation_result.errors(full: true).to_h.each do |attribute, errors|
            @new_item.errors.add(attribute, errors.join(", "))
          end
        end

        def add_errors_to_edit_form(validation_result)
          @active_item.assign_attributes(**validation_result.to_h.slice(:label, :short, :weight))

          validation_result.errors(full: true).to_h.each do |attribute, errors|
            @active_item.errors.add(attribute, errors.join(", "))
          end
        end

        def parse_parent_input(new_parent_input)
          case new_parent_input
          in [new_parent]
            input = MultiJSON.load(new_parent, symbolize_keys: true)[:value]
            new_parent = CustomField::Hierarchy::Item.including_children.find_by(id: input)

            if new_parent.present?
              Success(new_parent)
            else
              Failure(I18n.t(:notice_parent_item_not_found))
            end
          else
            Failure("Invalid input: #{new_parent_input}")
          end
        end

        def find_custom_field
          raise SubclassResponsibilityError
        end

        def find_active_item
          @active_item = if params[:id].present?
                           CustomField::Hierarchy::Item.including_children.find(params[:id])
                         else
                           @custom_field.hierarchy_root
                         end
        end
      end
    end
  end
end
