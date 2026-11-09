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
  class LlmModelsController < ApplicationController
    include OpTurbo::ComponentStream
    include PaginationHelper

    layout "admin"
    menu_item :llm_connection

    before_action :require_feature
    before_action :require_admin
    before_action :set_connection
    before_action :require_enabled_connection

    def index
      @query = ParamsToQueryService
                 .new(LlmModel, current_user, query_class: Queries::LlmModels::LlmModelQuery)
                 .call(params)
      @models = @query.results.paginate(page: page_param, per_page: per_page_param)
    end

    # Answers the sub-header's filter input, replacing just the table.
    def search
      index

      replace_via_turbo_stream(
        component: LlmConnections::ModelsTableComponent.new(rows: @models, connection: @connection)
      )
      turbo_streams << turbo_stream.push_state(llm_models_path(params.permit(:filters, :page, :per_page)))

      respond_with_turbo_streams
    end

    def refresh
      result = ::LlmConnections::SyncModelsService.new(@connection).call

      flash[result.success? ? :notice : :error] = t(result.success? ? ".success" : ".failure")
      redirect_to llm_models_path, status: :see_other
    end

    # Models an administrator enters by hand are necessary because not every
    # OpenAI-compatible server exposes a model list. A gateway may route
    # /v1/chat/completions and nothing else, in which case the operator knows the
    # model name and OpenProject cannot discover it.
    def new
      @llm_model = @connection.models.new
    end

    def edit
      @llm_model = @connection.models.find(params.expect(:id))
    end

    def create
      result = ::LlmModels::CreateService
                 .new(user: current_user)
                 .call(**llm_model_params, llm_connection: @connection)
      @llm_model = result.result

      respond_to_save(result, failure: :new)
    end

    def update
      @llm_model = @connection.models.find(params.expect(:id))
      result = ::LlmModels::UpdateService
                 .new(user: current_user, model: @llm_model)
                 .call(**llm_model_params)

      respond_to_save(result, failure: :edit)
    end

    def delete_dialog
      llm_model = @connection.models.manual.find(params.expect(:id))
      return refuse_env_named_default if @connection.env_named_default?(llm_model)

      respond_with_dialog LlmConnections::DeleteModelDialogComponent.new(llm_model)
    end

    def destroy
      llm_model = @connection.models.manual.find(params.expect(:id))
      result = ::LlmModels::DeleteService.new(user: current_user, model: llm_model).call
      return refuse_env_named_default if configured_from_env?(result)

      flash_outcome(result, model: llm_model.external_id)
      redirect_to llm_models_path, status: :see_other
    end

    def update_defaults
      result = ::LlmConnections::UpdateService
                 .new(user: current_user, model: @connection)
                 .call(**default_model_params)

      result.on_success { flash[:notice] = t("admin.llm_models.defaults.success") }
      result.on_failure { flash[:error] = result.errors.full_messages.join(", ") }

      redirect_to llm_models_path, status: :see_other
    end

    private

    def default_model_params
      params.expect(llm_connection: %i[default_chat_model_id default_embedding_model_id]).to_h.symbolize_keys
    end

    def set_connection
      @connection = LlmConnection.active_connection
    end

    def respond_to_save(result, failure:)
      return refuse_env_named_default if configured_from_env?(result)

      if result.success?
        flash[:notice] = t(".success", model: result.result.external_id)
        redirect_to llm_models_path, status: :see_other
      else
        render failure, status: :unprocessable_entity
      end
    end

    def flash_outcome(result, model:)
      if result.success?
        flash[:notice] = t(".success", model:)
      else
        flash[:error] = result.errors.full_messages.join(", ")
      end
    end

    def configured_from_env?(result)
      result.errors.of_kind?(:base, :configured_from_env)
    end

    def refuse_env_named_default
      flash[:error] = t("admin.llm_models.configured_from_env")
      redirect_to llm_models_path, status: :see_other
    end

    # The flag gates the endpoints, not only the menu entry: an unfinished page
    # must not accept writes just because somebody knows the URL.
    def require_feature
      render_404 unless OpenProject::FeatureDecisions.llm_connection_active?
    end

    # The models are a tab of the LLM settings, and that tab is offered only
    # while the AI features are switched on and a server is configured.
    def require_enabled_connection
      return if Setting.llm_features_enabled? && @connection.configured?

      flash[:notice] = t("admin.llm_connections.disabled_notice")
      redirect_to llm_connection_path, status: :see_other
    end

    # external_id is accepted on create, and on update for manually added models.
    def llm_model_params
      params.expect(
        llm_model: [:external_id, :display_name, :admin_context_window, :model_type, *capability_param_names]
      ).to_h.symbolize_keys
    end

    def capability_param_names
      Llm::Capabilities::CHAT.map { |capability| :"capability_#{capability}" }
    end
  end
end
