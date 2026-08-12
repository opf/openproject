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
  # Models an administrator enters by hand.
  #
  # Necessary because not every OpenAI-compatible server exposes a model list.
  # A gateway may route /v1/chat/completions and nothing else, in which case the
  # operator knows the model name and OpenProject cannot discover it.
  class LlmModelsController < ApplicationController
    include OpTurbo::ComponentStream

    layout "admin"
    menu_item :llm_connection

    before_action :require_admin
    before_action :set_connection

    def new
      @llm_model = @connection.models.new
    end

    def edit
      @llm_model = @connection.models.find(params.expect(:id))
      @verdicts = @connection.capability_verdicts.for_model(@llm_model.external_id).index_by(&:capability)
    end

    def create
      llm_model = @connection.models.new(llm_model_params.except(*capability_param_names).merge(manual: true))

      if save_with_capabilities(llm_model)
        flash[:notice] = t(".success", model: llm_model.external_id)
        redirect_to llm_connection_path, status: :see_other
      else
        # Re-rendered rather than redirected so the Primer form shows the error
        # inline against the field that caused it.
        @llm_model = llm_model
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @llm_model = @connection.models.find(params.expect(:id))

      ActiveRecord::Base.transaction do
        apply_attributes(@llm_model)
        apply_capabilities(@llm_model)
      end

      flash[:notice] = t(".success", model: @llm_model.external_id)
      redirect_to llm_connection_path, status: :see_other
    end

    def delete_dialog
      llm_model = @connection.models.manual.find(params.expect(:id))

      respond_with_dialog LlmConnections::DeleteModelDialogComponent.new(llm_model)
    end

    def destroy
      llm_model = @connection.models.manual.find(params.expect(:id))
      llm_model.destroy!

      flash[:notice] = t(".success", model: llm_model.external_id)
      redirect_to llm_connection_path, status: :see_other
    end

    # Hides a model from the pickers, or puts it back. Deliberately does not
    # touch +active+, which the catalogue sync owns and would overwrite.
    def toggle
      llm_model = @connection.models.find(params.expect(:id))

      # A withdrawn model has nothing to switch on; its toggle is rendered
      # disabled, and this refuses a request that got here anyway.
      return render(json: {}, status: :unprocessable_entity) unless llm_model.active?

      llm_model.update!(deactivated_at: llm_model.deactivated? ? nil : Time.current)

      render json: {}, status: :ok
    end

    private

    def set_connection
      @connection = LlmConnection.instance
    end

    def apply_attributes(llm_model)
      llm_model.assign_attributes(llm_model_params.except(:external_id, *capability_param_names))
      llm_model.save!
    end

    # external_id is only accepted when creating: verdicts and bindings reference
    # a model by that string, so renaming one would orphan both.
    def llm_model_params
      params.expect(llm_model: [:external_id, :display_name, :admin_context_window, *capability_param_names])
    end

    def capability_param_names
      Llm::Capabilities::ALL.map { |capability| :"capability_#{capability}" }
    end

    def save_with_capabilities(llm_model)
      ActiveRecord::Base.transaction do
        llm_model.save!
        apply_capabilities(llm_model)
      end

      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    # Stored as admin-sourced verdicts, which survive re-detection: an
    # administrator knows things about their deployment that neither a published
    # registry nor a probe can determine.
    def apply_capabilities(llm_model)
      submitted = llm_model_params

      Llm::Capabilities::ALL.each do |capability|
        assert(llm_model.external_id, capability, submitted[:"capability_#{capability}"].presence)
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
