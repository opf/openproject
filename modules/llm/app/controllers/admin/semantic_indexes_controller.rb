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
  class SemanticIndexesController < ApplicationController
    include OpTurbo::ComponentStream

    layout "admin"
    menu_item :llm_connection

    before_action :require_feature
    before_action :require_admin
    before_action :set_connection
    before_action :require_enabled_connection
    before_action :find_semantic_index,
                  only: %i[edit_dialog update deletion_dialog destroy start_indexing stop_indexing
                           activation_dialog activate]

    def new_dialog
      respond_with_dialog LlmConnections::SemanticIndexes::DialogComponent.new(SemanticIndex.new, connection: @connection)
    end

    def edit_dialog
      respond_with_dialog LlmConnections::SemanticIndexes::DialogComponent.new(@semantic_index, connection: @connection)
    end

    def create
      result = ::SemanticIndexes::CreateService
                 .new(user: current_user)
                 .call(semantic_index_params)

      respond_to_save(result, notice: t(:notice_successful_create))
    end

    def update
      result = ::SemanticIndexes::UpdateService
                 .new(user: current_user, model: @semantic_index)
                 .call(semantic_index_params)

      respond_to_save(result, notice: t(:notice_successful_update))
    end

    def deletion_dialog
      respond_with_dialog LlmConnections::SemanticIndexes::DeleteDialogComponent.new(@semantic_index)
    end

    def destroy
      result = ::SemanticIndexes::DeleteService
                 .new(user: current_user, model: @semantic_index)
                 .call

      if result.success?
        flash[:notice] = t(:notice_successful_delete)
      else
        flash[:error] = result.errors.full_messages
      end

      redirect_to llm_feature_bindings_path, status: :see_other
    end

    def start_indexing
      result = ::SemanticIndexes::StartIndexingService
                 .new(user: current_user, model: @semantic_index)
                 .call

      if result.success?
        flash[:notice] = t(".started", title: @semantic_index.title)
      else
        flash[:error] = result.message
      end

      redirect_to llm_feature_bindings_path, status: :see_other
    end

    def stop_indexing
      result = ::SemanticIndexes::StopIndexingService
                 .new(user: current_user, model: @semantic_index)
                 .call

      if result.success?
        flash[:notice] = t(".stopped", title: @semantic_index.title)
      else
        flash[:error] = result.message
      end

      redirect_to llm_feature_bindings_path, status: :see_other
    end

    def activation_dialog
      respond_with_dialog LlmConnections::SemanticIndexes::ActivateDialogComponent.new(
        @semantic_index, current: SemanticIndex.active
      )
    end

    def activate
      result = ::SemanticIndexes::ActivateService
                 .new(user: current_user, model: @semantic_index)
                 .call

      if result.success?
        flash[:notice] = t(".success", title: @semantic_index.title)
      else
        flash[:error] = result.message
      end

      redirect_to llm_feature_bindings_path, status: :see_other
    end

    def status
      replace_via_turbo_stream(
        component: LlmConnections::SemanticIndexes::BoxComponent.new(semantic_indexes: SemanticIndex.order(:created_at))
      )
      respond_with_turbo_streams
    end

    private

    def respond_to_save(result, notice:)
      result.on_success do
        flash[:notice] = notice
        redirect_to llm_feature_bindings_path, status: :see_other
      end

      result.on_failure do
        update_via_turbo_stream(
          component: LlmConnections::SemanticIndexes::FormComponent.new(result.result, connection: @connection),
          status: :unprocessable_entity
        )
        respond_with_turbo_streams
      end
    end

    def require_feature
      render_404 unless OpenProject::FeatureDecisions.llm_connection_active? &&
                        OpenProject::FeatureDecisions.semantic_search_active?
    end

    def set_connection
      @connection = LlmConnection.active_connection
    end

    def require_enabled_connection
      return if Setting.llm_features_enabled? && @connection.configured?

      flash[:notice] = t("admin.llm_connections.disabled_notice")
      redirect_to llm_connection_path, status: :see_other
    end

    def find_semantic_index
      @semantic_index = SemanticIndex.find(params.expect(:id))
    end

    def semantic_index_params
      params.expect(semantic_index: %i[title description model_id embedding_vector_dimensions context_token_length])
    end
  end
end
