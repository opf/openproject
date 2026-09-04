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
  class TextTransformActionsController < ::ApplicationController
    include OpTurbo::ComponentStream
    include AI::TextTransformActionsFeature

    before_action :require_admin
    before_action :require_ai_text_transform_actions_feature
    before_action :find_text_transform_action, only: %i[edit update deletion_dialog destroy toggle drop]

    menu_item :text_transform_actions

    layout "admin"

    def index
      @text_transform_actions = ordered_text_transform_actions
    end

    def new
      @text_transform_action = AI::TextTransformAction.new
    end

    def edit; end

    def create
      result = AI::TextTransformActions::CreateService
                 .new(user: current_user)
                 .call(text_transform_action_params)

      result.on_failure do
        @text_transform_action = result.result
        stream_form_component do |format|
          format.html { render :new, status: :unprocessable_entity }
        end
      end

      result.on_success do
        flash[:notice] = t(:notice_successful_create)
        redirect_to action: :index
      end
    end

    def update
      result = AI::TextTransformActions::UpdateService
                 .new(user: current_user, model: @text_transform_action)
                 .call(text_transform_action_params)

      result.on_failure do
        stream_form_component do |format|
          format.html { render :edit, status: :unprocessable_entity }
        end
      end

      result.on_success do
        flash[:notice] = t(:notice_successful_update)
        redirect_to action: :index
      end
    end

    def deletion_dialog
      respond_with_dialog Admin::TextTransformActions::DeleteDialogComponent.new(@text_transform_action)
    end

    def destroy
      result = AI::TextTransformActions::DeleteService
                 .new(user: current_user, model: @text_transform_action)
                 .call

      if result.success?
        flash[:notice] = t(:notice_successful_delete)
      else
        flash[:error] = result.errors.full_messages
      end

      redirect_to action: :index
    end

    def toggle
      if @text_transform_action.update(active: boolean_param(:value))
        render json: {}, status: :ok
      else
        render json: {}, status: :unprocessable_entity
      end
    end

    def enable_all
      set_all_active(true)
    end

    def disable_all
      set_all_active(false)
    end

    def drop
      moved = valid_drop_request? &&
        @text_transform_action.move_after_anchor(drop_params[:prev_id], scope: AI::TextTransformAction.all)

      if moved
        update_list_via_turbo_stream
        respond_with_turbo_streams
      else
        render_error_flash_message_via_turbo_stream(message: I18n.t(:error_invalid_list_move_anchor))
        respond_with_turbo_streams(status: :unprocessable_entity)
      end
    end

    def toggle_setting
      Setting.ai_text_transform_actions_enabled = boolean_param(:value)

      update_via_turbo_stream(component: Admin::TextTransformActions::SettingToggleComponent.new)
      update_list_via_turbo_stream
      respond_with_turbo_streams do |format|
        format.html { redirect_to action: :index }
      end
    end

    private

    def find_text_transform_action
      @text_transform_action = AI::TextTransformAction.find(params.expect(:id))
    end

    def ordered_text_transform_actions
      AI::TextTransformAction.ordered.includes(:types)
    end

    def text_transform_action_params
      params.expect(ai_text_transform_action: [:label, :prompt, :usage_scope, :injects_type_template, { type_ids: [] }])
    end

    def boolean_param(key)
      ActiveRecord::Type::Boolean.new.cast(params[key])
    end

    def set_all_active(active)
      AI::TextTransformAction.update_all(active:, updated_at: Time.current)

      update_list_via_turbo_stream
      respond_with_turbo_streams do |format|
        format.html { redirect_to action: :index }
      end
    end

    def update_list_via_turbo_stream
      update_via_turbo_stream(
        component: Admin::TextTransformActions::IndexComponent.new(text_transform_actions: ordered_text_transform_actions),
        method: :morph
      )
    end

    def stream_form_component(&)
      update_via_turbo_stream(component: Admin::TextTransformActions::FormComponent.new(@text_transform_action))
      respond_with_turbo_streams(&)
    end

    # The raw list_id is checked because permit cannot distinguish absent from
    # filtered-out values, and prev_id must be a scalar to reach the anchor lookup.
    def valid_drop_request?
      drop_params[:list_type] == AI::TextTransformAction::SORTABLE_LIST_TYPE &&
        params[:list_id].blank? &&
        drop_params.key?(:prev_id)
    end

    def drop_params
      @drop_params ||= params.permit(:list_type, :list_id, :prev_id)
    end
  end
end
