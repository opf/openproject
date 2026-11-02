# frozen_string_literal: true

module TestManagement
  module Assistant
    # Creates or updates a saved AI provider (0021), for the admin form and the API.
    #
    # form: the provider form keys (assistant_provider, assistant_base_url, assistant_model,
    #       assistant_auth_style, assistant_api_key, remove_api_key, assistant_timeout,
    #       assistant_max_tokens) plus
    #   name          required, unique (case-insensitive)
    #   user_models   other models users may pick (array, or one per line / comma separated)
    #   make_default  "1": becomes the default provider (the first provider always does)
    #   verify_model  "1": one tiny chat request to the model before saving (AI::ConnectionTest
    #                 #verify_model); a failure keeps everything unsaved
    #
    # Validation and the encrypted key come from ProviderConfig.apply with this provider's stored
    # values, so the 0019b rule holds per provider: a blank key field keeps the stored key only while
    # the preset and host stay the same.
    class ProviderSaveService
      FORM_KEYS = %w[assistant_provider assistant_base_url assistant_model assistant_auth_style assistant_api_key
                     remove_api_key assistant_timeout assistant_max_tokens].freeze

      Result = Struct.new(:success, :provider, :errors, :verification, keyword_init: true) do
        def success? = success
      end

      attr_reader :provider

      def initialize(provider)
        @provider = provider
      end

      def call(form)
        form = form.to_h.stringify_keys
        merged, errors = ProviderConfig.apply(provider.new_record? ? {} : provider.settings, form.slice(*FORM_KEYS))
        provider.name = form["name"].to_s.strip if form.key?("name") || provider.new_record?
        provider.user_models = form["user_models"] if form.key?("user_models")
        provider.assign_settings(merged) if errors.empty?
        provider.validate
        errors += provider.errors.full_messages
        return failure(errors) if errors.any?

        if truthy?(form["verify_model"])
          verification = AI::ConnectionTest.new(provider.config).verify_model
          return failure([verification.message], verification) unless verification.ok?
        end

        save!(make_default: truthy?(form["make_default"]))
        Result.new(success: true, provider:, errors: [], verification:)
      end

      private

      def save!(make_default:)
        TestManagement::AssistantProvider.transaction do
          provider.save!
          others = TestManagement::AssistantProvider.where(is_default: true).where.not(id: provider.id)
          provider.make_default! if make_default || !others.exists?
        end
      end

      def failure(errors, verification = nil)
        Result.new(success: false, provider:, errors: errors.uniq, verification:)
      end

      def truthy?(value)
        ActiveModel::Type::Boolean.new.cast(value) == true
      end
    end
  end
end
