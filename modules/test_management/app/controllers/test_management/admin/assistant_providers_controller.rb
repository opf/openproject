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

module TestManagement
  module Admin
    class AssistantProvidersController < ApplicationController
      layout "admin"
      menu_item :test_management

      before_action :require_admin
      before_action :find_provider, only: %i[edit update destroy make_default]

      FORM_PARAMS = %i[name user_models make_default verify_model assistant_provider assistant_base_url assistant_model
                       assistant_model_choice assistant_auth_style assistant_api_key remove_api_key assistant_timeout
                       assistant_max_tokens].freeze

      def index
        redirect_to back_path
      end

      def new
        @record = TestManagement::AssistantProvider.new(preset: TestManagement::Assistant::AI::Provider::DEFAULT_KEY)
        @settings = initial_settings(@record)
      end

      def edit
        @settings = initial_settings(@record)
      end

      def create
        @record = TestManagement::AssistantProvider.new
        save(:new)
      end

      def update
        save(:edit)
      end

      def destroy
        @record.destroy!
        TestManagement::AssistantProvider.ensure_default!
        flash[:notice] = I18n.t(:notice_successful_delete)
        redirect_to back_path
      end

      def make_default
        @record.make_default!
        flash[:notice] = I18n.t("test_management.admin.assistant.providers_list.made_default", name: @record.name)
        redirect_to back_path
      end

      def provider_form
        @record = record_for_form
        @settings = preset_switch(form_params)
        render turbo_stream: turbo_stream.replace(
          "tm-assistant-provider-fields",
          partial: "test_management/admin/settings/provider_fields",
          locals: {
            settings: @settings,
            provider: @record.config,
            test_result: nil,
            test_url: test_connection_test_management_admin_assistant_providers_path
          }
        )
      end

      def test_connection # rubocop:disable Metrics/AbcSize
        @record = record_for_form
        form = form_params
        merged, errors = TestManagement::Assistant::ProviderConfig.apply(@record.new_record? ? {} : @record.settings,
                                                                         form.slice(*TestManagement::Assistant::ProviderSaveService::FORM_KEYS))
        @test_result =
          if errors.any?
            TestManagement::Assistant::AI::ConnectionTest::Result.new(ok: false, models: [], error_kind: :invalid,
                                                                      message: errors.join(" "), listed: false)
          else
            TestManagement::Assistant::AI::ConnectionTest.new(TestManagement::Assistant::ProviderConfig.new(merged)).call
          end
        @settings = initial_settings(@record).merge(form)

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace("tm-assistant-model-field",
                                                      partial: "test_management/admin/settings/model_field",
                                                      locals: { settings: @settings, test_result: @test_result })
          end
          format.html { render(@record.new_record? ? :new : :edit, status: @test_result.ok? ? :ok : :unprocessable_entity) }
        end
      end

      private

      def find_provider
        @record = TestManagement::AssistantProvider.find_by(id: params[:id])
        render_404 unless @record
      end

      def record_for_form
        id = params[:provider_id].presence
        (id && TestManagement::AssistantProvider.find_by(id:)) || TestManagement::AssistantProvider.new
      end

      def save(template) # rubocop:disable Metrics/AbcSize
        form = form_params
        result = TestManagement::Assistant::ProviderSaveService.new(@record).call(form)
        if result.success?
          flash[:notice] = I18n.t(:notice_successful_update)
          redirect_to back_path
        else
          @settings = initial_settings(@record).merge(form).merge("assistant_api_key" => nil)
          @test_result = result.verification
          @record_errors = result.errors
          flash.now[:error] = result.errors.join(" ")
          render template, status: :unprocessable_entity
        end
      end

      def initial_settings(record) # rubocop:disable Metrics/AbcSize
        settings = record.new_record? ? { "assistant_provider" => record.preset } : record.settings
        settings.merge(
          "name" => record.name, "user_models" => Array(record.user_models).join("\n"),
          "make_default" => record.is_default || !TestManagement::AssistantProvider.where.not(id: record.id).exists?,
          "verify_model" => !record.preset_definition.key_scoped_models?
        ).with_indifferent_access
      end

      def form_params
        form = params.permit(*FORM_PARAMS).to_h
        choice = form.delete("assistant_model_choice")
        form["assistant_model"] = choice if choice.present?
        form
      end

      def preset_switch(form) # rubocop:disable Metrics/AbcSize
        previous = params[:assistant_provider_was].to_s
        target = TestManagement::Assistant::AI::Provider.find(form["assistant_provider"])
        settings = initial_settings(@record).merge(form)
        settings[:assistant_provider] = target.key
        return settings if previous == target.key

        settings[:assistant_base_url] = target.base_url
        settings[:assistant_model] = ""
        settings.delete(:verify_model)
        settings
      end

      def back_path
        test_management_admin_settings_path(anchor: "tm-assistant-providers")
      end
      helper_method :back_path
    end
  end
end
