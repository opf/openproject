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
  class TextActionsController < ::ApplicationController
    include OpTurbo::ComponentStream
    include AI::TextActionsFeature
    include SortableLists::DropRequestValidation

    configure_drop_request list_type: AI::TextAction::SORTABLE_LIST_TYPE, list_id_scoped: false

    before_action :require_admin
    before_action :require_ai_text_actions_feature

    guard_enterprise_feature(ENTERPRISE_FEATURE, except: :index) do
      redirect_to action: :index
    end

    before_action :find_text_action, only: %i[edit update deletion_dialog destroy toggle drop]

    menu_item :text_actions

    layout "admin"

    def index
      @text_actions = ordered_text_actions
    end

    def new
      @text_action = AI::TextAction.new
    end

    def edit; end

    def create
      result = AI::TextActions::CreateService
                 .new(user: current_user)
                 .call(text_action_params)

      result.on_failure do
        @text_action = result.result
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
      result = AI::TextActions::UpdateService
                 .new(user: current_user, model: @text_action)
                 .call(text_action_params)

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
      respond_with_dialog Admin::TextActions::DeleteDialogComponent.new(@text_action)
    end

    def destroy
      result = AI::TextActions::DeleteService
                 .new(user: current_user, model: @text_action)
                 .call

      if result.success?
        flash[:notice] = t(:notice_successful_delete)
      else
        flash[:error] = result.errors.full_messages
      end

      redirect_to action: :index
    end

    def toggle
      if @text_action.update(active: boolean_param(:value))
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
        @text_action.move_after_anchor(drop_params[:prev_id], scope: AI::TextAction.all)

      if moved
        update_list_via_turbo_stream
        respond_with_turbo_streams
      else
        render_error_flash_message_via_turbo_stream(message: I18n.t(:error_invalid_list_move_anchor))
        respond_with_turbo_streams(status: :unprocessable_entity)
      end
    end

    private

    def find_text_action
      @text_action = AI::TextAction.find(params.expect(:id))
    end

    def ordered_text_actions
      AI::TextAction.ordered.includes(:types)
    end

    def text_action_params
      params.expect(ai_text_action: [:label, :prompt, :usage_scope, :injects_type_template, { type_ids: [] }])
    end

    def boolean_param(key)
      ActiveRecord::Type::Boolean.new.cast(params[key])
    end

    def set_all_active(active)
      AI::TextAction.update_all(active:, updated_at: Time.current)

      update_list_via_turbo_stream
      respond_with_turbo_streams do |format|
        format.html { redirect_to action: :index }
      end
    end

    def update_list_via_turbo_stream
      update_via_turbo_stream(
        component: Admin::TextActions::IndexComponent.new(text_actions: ordered_text_actions),
        method: :morph
      )
    end

    def stream_form_component(&)
      update_via_turbo_stream(component: Admin::TextActions::FormComponent.new(@text_action))
      respond_with_turbo_streams(&)
    end
  end
end
