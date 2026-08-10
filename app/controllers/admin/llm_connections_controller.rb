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
  class LlmConnectionsController < ApplicationController
    include OpTurbo::ComponentStream

    layout "admin"
    menu_item :llm_connection

    before_action :require_admin
    before_action :set_connection

    def show; end

    def update
      result = ::LlmConnections::UpdateService
                 .new(user: current_user, model: @connection)
                 .call(**llm_connection_params)

      result.on_success { redirect_after_save }
      result.on_failure { render_form_with_errors }
    end

    def refresh_models
      result = ::LlmConnections::SyncModelsService.new(@connection).call

      if result.success?
        redirect_with_notice(t(".success"))
      else
        redirect_with_error(t(".failure"))
      end
    end

    def delete_api_key
      @connection.update!(api_key: nil)

      redirect_with_notice(t(".success"))
    end

    private

    def set_connection
      @connection = LlmConnection.instance
    end

    # A connection can be perfectly usable without offering a model list, so the
    # save succeeds either way; the administrator is told what to do next rather
    # than being left with an empty table and no explanation.
    def redirect_after_save
      if @connection.reload.models.none?
        flash[:warning] = t(".no_models")
      else
        flash[:notice] = t(".success")
      end

      redirect_to llm_connection_path, status: :see_other
    end

    def render_form_with_errors
      update_via_turbo_stream(component: ::LlmConnections::FormComponent.new(@connection))
      respond_with_turbo_streams { |format| format.html { render :show } }
    end

    def redirect_with_notice(message)
      flash[:notice] = message
      redirect_to llm_connection_path, status: :see_other
    end

    def redirect_with_error(message)
      flash[:error] = message
      redirect_to llm_connection_path, status: :see_other
    end

    # A blank API key means "keep the stored one": the form never renders the
    # saved value, so submitting it unchanged posts an empty string.
    def llm_connection_params
      permitted = params.expect(
        llm_connection: %i[enabled api_format base_url api_key default_chat_model_id default_embedding_model_id]
      )
      permitted.delete(:api_key) if permitted[:api_key].blank?
      permitted.to_h.symbolize_keys
    end
  end
end
