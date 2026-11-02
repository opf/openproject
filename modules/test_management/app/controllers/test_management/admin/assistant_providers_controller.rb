# frozen_string_literal: true

module TestManagement
  module Admin
    # Saved AI providers of the Test Assistant (0021), listed on Administration > Test management:
    # add, edit, delete, make default, "Test connection". The form is the provider form of 0017
    # (preset select re-rendering the preset fields, "Test connection" listing the models the key can
    # use) plus name, the models users may pick and "Check the model when saving".
    # return_to (a local path, e.g. the assistant page whose header offered "Add new provider…") is
    # where Save and Cancel go back to.
    class AssistantProvidersController < ApplicationController
      layout "admin"
      menu_item :test_management

      before_action :require_admin
      before_action :find_provider, only: %i[edit update destroy make_default]

      FORM_PARAMS = %i[name user_models make_default verify_model assistant_provider assistant_base_url assistant_model
                       assistant_model_choice assistant_auth_style assistant_api_key remove_api_key assistant_timeout
                       assistant_max_tokens].freeze

      def index
        redirect_to test_management_admin_settings_path(anchor: "tm-assistant-providers")
      end

      def new
        @record = TestManagement::AssistantProvider.new(preset: "openai")
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

      # Preset select changed (refresh-on-form-changes, POST): re-render the preset fields. Nothing is saved.
      def provider_form
        @record = record_for_form
        @settings = preset_switch(form_params)
        render turbo_stream: turbo_stream.replace("tm-assistant-provider-fields",
                                                  partial: "test_management/admin/settings/provider_fields",
                                                  locals: { settings: @settings, provider: @record.config, test_result: nil,
                                                            test_url: test_connection_test_management_admin_assistant_providers_path })
      end

      # "Test connection" with the entered (unsaved) values; a blank key field uses this provider's
      # stored key (only for the same preset and host, 0019b). Never renders or logs the key.
      def test_connection
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

      def save(template)
        form = form_params
        result = TestManagement::Assistant::ProviderSaveService.new(@record).call(form)
        if result.success?
          # Added from the assistant header ("Add new provider…"): the admin goes back using it.
          if template == :new && params[:return_to].present?
            TestManagement::Assistant::ProviderChoice.select!(current_user,
                                                              result.provider.id.to_s)
          end
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

      # Form values of a provider; new providers check the model on save unless the preset lists only
      # the key's models.
      def initial_settings(record)
        settings = record.new_record? ? { "assistant_provider" => record.preset } : record.settings
        settings.merge(
          "name" => record.name, "user_models" => Array(record.user_models).join("\n"),
          "make_default" => record.is_default || !TestManagement::AssistantProvider.where.not(id: record.id).exists?,
          "verify_model" => !record.preset_definition.key_scoped_models?
        ).with_indifferent_access
      end

      # The model select ("assistant_model_choice", after a connection test) wins over the free-text
      # field unless "Other" (blank) is chosen.
      def form_params
        form = params.permit(*FORM_PARAMS).to_h
        choice = form.delete("assistant_model_choice")
        form["assistant_model"] = choice if choice.present?
        form
      end

      # Switching the preset resets base URL and model unless the base URL was customized (not a
      # preset default) and the target is "custom".
      def preset_switch(form)
        previous = params[:assistant_provider_was].to_s
        target = TestManagement::Assistant::AI::Provider.find(form["assistant_provider"])
        settings = initial_settings(@record).merge(form)
        settings[:assistant_provider] = target.key
        return settings if previous == target.key

        entered = form["assistant_base_url"].to_s.strip
        keep_url = target.custom? && entered.present? && !TestManagement::Assistant::AI::Provider.default_base_url?(entered)
        settings[:assistant_base_url] = keep_url ? entered : target.base_url
        settings[:assistant_model] = ""
        settings.delete(:verify_model) # the new preset's default (on unless it lists only the key's models)
        settings
      end

      def back_path
        default = test_management_admin_settings_path(anchor: "tm-assistant-providers")
        RedirectPolicy.new(
          params[:return_to],
          hostname: request.host,
          default:,
          return_escaped: false
        ).redirect_url
      end
      helper_method :back_path
    end
  end
end
