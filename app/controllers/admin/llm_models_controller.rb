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
        component: LlmConnections::Models::IndexComponent.new(@models, connection: @connection)
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
      @verdicts = @connection.capability_verdicts.for_model(@llm_model.external_id).index_by(&:capability)
    end

    def create
      submitted = llm_model_params
      llm_model = @connection.models.new(submitted.except(*capability_param_names).merge(manual: true))

      if save_with_capabilities(llm_model, submitted)
        flash[:notice] = t(".success", model: llm_model.external_id)
        redirect_to llm_models_path, status: :see_other
      else
        # Re-rendered rather than redirected so the Primer form shows the error
        # inline against the field that caused it.
        @llm_model = llm_model
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @llm_model = @connection.models.find(params.expect(:id))

      if update_with_capabilities(@llm_model)
        flash[:notice] = t(".success", model: @llm_model.external_id)
        redirect_to llm_models_path, status: :see_other
      else
        # Re-rendered rather than redirected so the Primer form shows the error
        # inline against the field that caused it, e.g. a rename that collides
        # with an existing model id.
        @verdicts = @connection.capability_verdicts.for_model(@llm_model.external_id_was).index_by(&:capability)
        render :edit, status: :unprocessable_entity
      end
    end

    def delete_dialog
      llm_model = @connection.models.manual.find(params.expect(:id))

      respond_with_dialog LlmConnections::DeleteModelDialogComponent.new(llm_model)
    end

    def destroy
      llm_model = @connection.models.manual.find(params.expect(:id))
      destroy_with_verdicts(llm_model)

      flash[:notice] = t(".success", model: llm_model.external_id)
      redirect_to llm_models_path, status: :see_other
    end

    private

    def set_connection
      @connection = LlmConnection.active_connection
    end

    # Verdicts are keyed by the identifier string, not by foreign key, so they
    # would silently apply to a future model re-added under the same name.
    def destroy_with_verdicts(llm_model)
      ActiveRecord::Base.transaction do
        llm_model.destroy!
        @connection.capability_verdicts.for_model(llm_model.external_id).delete_all
      end
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

    def update_with_capabilities(llm_model)
      submitted = llm_model_params
      pin_type = type_chosen?(llm_model, submitted)

      saved = false
      ActiveRecord::Base.transaction do
        previous_external_id = llm_model.external_id
        llm_model.assign_attributes(updatable_attributes(llm_model, submitted))
        raise ActiveRecord::Rollback unless llm_model.save

        llm_model.cascade_rename!(previous_external_id)
        apply_capabilities(llm_model, submitted, pin_type:)
        saved = true
      end
      saved
    rescue ActiveRecord::RecordInvalid
      false
    end

    # A discovered model is named by the server; only a hand-entered one may be
    # renamed here, and everything referencing the old name follows it.
    def updatable_attributes(llm_model, submitted)
      attributes = submitted.except(*capability_param_names)
      llm_model.manual? ? attributes : attributes.except(:external_id)
    end

    def type_chosen?(llm_model, submitted)
      submitted[:model_type].present? && submitted[:model_type] != llm_model.model_type.to_s
    end

    # external_id is accepted on create, and on update for manually added models.
    def llm_model_params
      params.expect(
        llm_model: [:external_id, :display_name, :admin_context_window, :model_type, *capability_param_names]
      )
    end

    def capability_param_names
      Llm::Capabilities::CHAT.map { |capability| :"capability_#{capability}" }
    end

    def save_with_capabilities(llm_model, submitted)
      ActiveRecord::Base.transaction do
        llm_model.save!
        apply_capabilities(llm_model, submitted, pin_type: true)
      end

      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    # Stored as admin-sourced verdicts, which survive re-detection: an
    # administrator knows things about their deployment that neither a published
    # registry nor a probe can determine.
    #
    # The type is only pinned when the administrator picked one that differs from
    # what the model is today, so re-saving a discovered model does not freeze a
    # type that a probe or a refresh could still correct.
    def apply_capabilities(llm_model, submitted, pin_type:)
      embedding = submitted[:model_type] == "embedding"
      assert(llm_model.external_id, :embeddings, embedding ? "supported" : "unsupported") if pin_type

      Llm::Capabilities::CHAT.each do |capability|
        state = embedding ? nil : submitted[:"capability_#{capability}"].presence
        assert(llm_model.external_id, capability, state)
      end
    end

    def assert(model_id, capability, state)
      verdict = @connection.capability_verdicts
                           .find_or_initialize_by(model_id:, capability: capability.to_s)

      if state.blank?
        # "Not specified" clears an assertion rather than recording ignorance as
        # fact; detection may fill it in later.
        verdict.destroy! if verdict.persisted? && verdict.source_admin?
      else
        verdict.update!(state:, source: "admin", checked_at: Time.current)
      end
    end
  end
end
