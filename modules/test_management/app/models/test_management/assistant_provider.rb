# frozen_string_literal: true

module TestManagement
  # A saved AI provider of the Test Assistant (0021). Administrators keep several (OpenAI, a local
  # Ollama, OpenRouter, …); one is the default. Users pick one, and optionally another of its models,
  # in the assistant header (TestManagement::Assistant::ProviderChoice).
  #
  #   preset, base_url, auth_style, api_key_ciphertext, model, timeout, max_tokens
  #               the same values and rules as the former single provider setting: validation, the
  #               encrypted write-only key and the 0019b rule "a blank key never carries the stored
  #               key over to another provider or host" all come from Assistant::ProviderConfig.apply
  #               (see #settings / #assign_settings). The key is never rendered or returned by the API.
  #   user_models other models of this provider users may choose instead of the default model
  class AssistantProvider < ApplicationRecord
    self.table_name = "tm_assistant_providers"

    NAME_LIMIT = 100
    MAX_USER_MODELS = 20

    has_many :generations, class_name: "TestManagement::AssistantGeneration", foreign_key: :provider_id,
                           inverse_of: false, dependent: :nullify
    has_many :messages, class_name: "TestManagement::AssistantMessage", foreign_key: :provider_id,
                        inverse_of: false, dependent: :nullify

    validates :name, presence: true, length: { maximum: NAME_LIMIT }, uniqueness: { case_sensitive: false }
    validate :user_models_valid

    scope :ordered, -> { order(is_default: :desc).order(Arel.sql("LOWER(tm_assistant_providers.name)"), :id) }

    def self.default_provider
      find_by(is_default: true) || ordered.first
    end

    # After a delete: the first remaining provider becomes the default.
    def self.ensure_default!
      return if exists?(is_default: true)

      ordered.first&.make_default!
    end

    # The values in the shape of the former plugin setting (ProviderConfig / ProviderConfig.apply).
    def settings
      {
        "assistant_provider" => preset, "assistant_base_url" => base_url.to_s, "assistant_model" => model.to_s,
        "assistant_api_key_ciphertext" => api_key_ciphertext, "assistant_auth_style" => auth_style,
        "assistant_timeout" => timeout, "assistant_max_tokens" => max_tokens
      }
    end

    # Takes the validated result of ProviderConfig.apply(settings, form).
    def assign_settings(merged)
      merged = merged.to_h.stringify_keys
      self.preset = merged["assistant_provider"].presence || Assistant::AI::Provider::DEFAULT_KEY
      self.base_url = merged["assistant_base_url"].presence
      self.model = merged["assistant_model"].presence
      self.api_key_ciphertext = merged["assistant_api_key_ciphertext"].presence
      self.auth_style = merged["assistant_auth_style"].presence
      self.timeout = merged["assistant_timeout"].presence
      self.max_tokens = merged["assistant_max_tokens"].presence
      self
    end

    # model: one of #selectable_models (anything else falls back to the default model).
    def config(model: nil)
      values = settings
      values["assistant_model"] = model if model.present? && selectable_models.include?(model)
      Assistant::ProviderConfig.new(values, name:, provider_id: id)
    end

    def preset_definition
      Assistant::AI::Provider.find(preset)
    end

    # The default model first, then the extra models users may pick.
    def selectable_models
      ([model] + Array(user_models)).map { it.to_s.strip }.compact_blank.uniq
    end

    def user_models=(value)
      list = value.is_a?(String) ? value.split(/[\n,]/) : Array(value)
      super(list.map { it.to_s.strip }.compact_blank.uniq)
    end

    def make_default!
      transaction do
        self.class.where.not(id:).where(is_default: true).update_all(is_default: false)
        update!(is_default: true)
      end
    end

    delegate :configured?, to: :config

    def display_label(chosen = model)
      "#{name} · #{chosen.presence || '?'}"
    end

    private

    def user_models_valid
      list = Array(user_models)
      errors.add(:user_models, :too_many, count: MAX_USER_MODELS) if list.size > MAX_USER_MODELS
      errors.add(:user_models, :invalid) if list.any? { |m| !m.is_a?(String) || m.length > 255 }
    end
  end
end
