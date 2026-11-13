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

module Admin
  module CustomFields
    module Hierarchy
      class ItemsBaseController < ApplicationController
        include OpTurbo::ComponentStream

        layout :admin_or_frame_layout

        before_action :require_admin
        before_action :find_custom_field
        before_action :find_active_item, except: %i[edit update move change_parent destroy]
        before_action :find_non_root_item, only: %i[edit update move change_parent destroy]

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
          call = ::CustomFields::Hierarchy::Items::CreateService
            .new(user: current_user)
            .call(**item_attributes, parent: @active_item, sort_order: params[:sort_order])

          if call.success?
            redirect_to action: :new, position: call.result.sort_order + 1
          else
            @new_item = call.result
            render :new
          end
        end

        def update
          call = ::CustomFields::Hierarchy::Items::UpdateService
            .new(user: current_user, model: @active_item)
            .call(item_attributes)

          if call.success?
            redirect_to action: :show, id: @active_item.parent, status: :see_other
          else
            update_via_turbo_stream(
              component: ItemComponent.new(item: @active_item, custom_field: @custom_field, show_edit_form: true)
            )
            respond_with_turbo_streams
          end
        end

        def move
          ::CustomFields::Hierarchy::Items::UpdateService
            .new(user: current_user, model: @active_item)
            .call(sort_order: params.require(:new_sort_order))

          redirect_to action: :show, id: @active_item.parent, status: :see_other
        end

        def change_parent
          new_parent = find_new_parent
          if new_parent.nil?
            render_error_flash_message_via_turbo_stream(message: I18n.t(:notice_parent_item_not_found))
            return respond_with_turbo_streams(&:html)
          end

          call = ::CustomFields::Hierarchy::Items::UpdateService
            .new(user: current_user, model: @active_item)
            .call(parent: new_parent)

          if call.success?
            redirect_to action: :show, id: new_parent, status: :see_other, notice: I18n.t(:notice_successful_update)
          else
            render_error_flash_message_via_turbo_stream(message: call.errors.full_messages.to_sentence)
            respond_with_turbo_streams(&:html)
          end
        end

        def destroy
          call = ::CustomFields::Hierarchy::Items::DeleteService
            .new(user: current_user, model: @active_item)
            .call

          if call.success?
            update_via_turbo_stream(component: ItemsComponent.new(item: @active_item.parent.reload))
          else
            render_error_flash_message_via_turbo_stream(message: call.errors.full_messages.to_sentence)
          end

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

        def item_attributes
          { label: params[:label], short: params[:short], weight: params[:weight] }
        end

        def find_new_parent
          new_parent_input = params.require(:custom_field_hierarchy_forms_new_parent_form_model).require(:new_parent)
          return unless new_parent_input in [new_parent_json]

          new_parent_id = MultiJSON.load(new_parent_json, symbolize_keys: true)[:value]
          @custom_field.hierarchy_root.self_and_descendants.find_by(id: new_parent_id)
        end

        def find_custom_field
          raise SubclassResponsibilityError
        end

        def find_active_item
          @active_item = if params[:id].present?
                           @custom_field.hierarchy_root.self_and_descendants.including_children.find(params.expect(:id))
                         else
                           @custom_field.hierarchy_root
                         end
        end

        def find_non_root_item
          @active_item = @custom_field.hierarchy_root.descendants.including_children.find(params.expect(:id))
        end
      end
    end
  end
end
