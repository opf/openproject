# frozen_string_literal: true

module TestManagement
  module Assistant
    # The provider and model a user works with (0021): the one picked in the assistant header
    # (stored in tm_user_preferences: assistant_provider_id and assistant_models { provider id =>
    # model }), else the default provider with its default model. A picked model that is no longer
    # offered by the provider falls back to the provider's default model; a deleted provider falls
    # back to the default provider.
    #
    # Generations and chat messages remember the choice (provider_id, chosen_model) when they are
    # created, so the background job uses what the user saw when sending.
    class ProviderChoice
      attr_reader :provider, :model

      def self.for(user)
        prefs = TestManagement::UserPreference.for(user)
        provider = TestManagement::AssistantProvider.find_by(id: prefs.assistant_provider_id) if prefs.assistant_provider_id.present?
        provider ||= TestManagement::AssistantProvider.default_provider
        new(provider, provider && Hash(prefs.assistant_models)[provider.id.to_s])
      end

      def self.for_record(record)
        provider = TestManagement::AssistantProvider.find_by(id: record.provider_id) if record.provider_id
        return new(provider, record.chosen_model) if provider

        self.for(record.user)
      end

      # value: "<provider id>" or "<provider id>:<model>" (the model may contain ":", e.g. llama3.1:8b).
      # Returns false for an unknown provider or a model the provider does not offer.
      def self.select!(user, value)
        match = value.to_s.match(/\A(\d+)(?::(.+))?\z/m)
        return false unless match && user.respond_to?(:logged?) && user.logged?

        provider = TestManagement::AssistantProvider.find_by(id: match[1].to_i)
        model = match[2].presence || provider&.model
        return false unless provider&.selectable_models&.include?(model)

        prefs = TestManagement::UserPreference.for(user)
        prefs.assistant_provider_id = provider.id
        prefs.assistant_models = Hash(prefs.assistant_models).merge(provider.id.to_s => model)
        prefs.save!
      end

      def initialize(provider, model)
        @provider = provider
        @model = provider&.selectable_models&.include?(model.to_s) ? model.to_s : provider&.model.to_s
      end

      # Without saved providers: the setting stored before 0021 (ProviderConfig.current).
      def config
        provider ? provider.config(model:) : ProviderConfig.current
      end

      def value
        provider && "#{provider.id}:#{model}"
      end

      def label
        provider&.display_label(model)
      end
    end
  end
end
