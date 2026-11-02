# frozen_string_literal: true

# Test Assistant (0021): several saved AI providers instead of one.
# * tm_assistant_providers: name, preset, base URL, authentication, encrypted API key, model,
#   models users may pick (user_models), timeout, max tokens; exactly one is the default.
# * The provider configured before (Setting.plugin_openproject_test_management assistant_*) becomes
#   the first provider and the default. The key is copied as it is (still encrypted with the same
#   salt) and the assistant_* keys are removed from the plugin setting. Down writes the default
#   provider back into the setting.
# * Generations and chat messages remember the provider (provider_id, nullified when the provider is
#   deleted) and the model that was asked (chosen_model), next to the existing provider_model label.
class CreateTmAssistantProviders < ActiveRecord::Migration[8.0]
  SETTING_KEYS = %w[assistant_provider assistant_base_url assistant_model assistant_api_key_ciphertext assistant_auth_style
                    assistant_timeout assistant_max_tokens].freeze
  PRESET_NAMES = { "openai" => "OpenAI", "anthropic" => "Anthropic", "openrouter" => "OpenRouter", "ollama" => "Ollama",
                   "xai" => "xAI", "mistral" => "Mistral", "azure" => "Azure OpenAI", "custom" => "Default" }.freeze

  class MigrationProvider < ApplicationRecord
    self.table_name = "tm_assistant_providers"
  end

  def up
    create_table :tm_assistant_providers do |t|
      t.string :name, null: false, limit: 100
      t.string :preset, null: false, default: "custom", limit: 32
      t.string :base_url, limit: 1024
      t.string :auth_style, limit: 16
      t.text :api_key_ciphertext
      t.string :model, limit: 255
      t.jsonb :user_models, null: false, default: []
      t.integer :timeout
      t.integer :max_tokens
      t.boolean :is_default, null: false, default: false
      t.timestamps
    end
    add_index :tm_assistant_providers, "lower(name)", unique: true, name: "index_tm_assistant_providers_on_lower_name"
    add_index :tm_assistant_providers, :is_default, unique: true, where: "is_default",
                                                    name: "index_tm_assistant_providers_one_default"

    %i[tm_assistant_generations tm_assistant_messages].each do |table|
      add_reference table, :provider, foreign_key: { to_table: :tm_assistant_providers, on_delete: :nullify }
      add_column table, :chosen_model, :string, limit: 255
    end

    move_setting_to_provider
  end

  def down
    restore_setting_from_provider
    %i[tm_assistant_generations tm_assistant_messages].each do |table|
      remove_column table, :chosen_model
      remove_reference table, :provider, foreign_key: { to_table: :tm_assistant_providers }
    end
    drop_table :tm_assistant_providers
  end

  private

  def move_setting_to_provider
    settings = plugin_settings
    old = settings.slice(*SETTING_KEYS)
    # Only a provider that was actually set up (model, base URL or key); a bare preset choice is not.
    if old.slice("assistant_model", "assistant_base_url", "assistant_api_key_ciphertext").values.any?(&:present?)
      preset = PRESET_NAMES.key?(old["assistant_provider"].to_s) ? old["assistant_provider"].to_s : "custom"
      MigrationProvider.reset_column_information
      MigrationProvider.create!(
        name: PRESET_NAMES.fetch(preset), preset:, base_url: old["assistant_base_url"].presence,
        auth_style: old["assistant_auth_style"].presence, api_key_ciphertext: old["assistant_api_key_ciphertext"].presence,
        model: old["assistant_model"].presence, user_models: [], timeout: old["assistant_timeout"].presence&.to_i,
        max_tokens: old["assistant_max_tokens"].presence&.to_i, is_default: true
      )
    end
    self.plugin_settings = settings.except(*SETTING_KEYS) if old.any?
  end

  def restore_setting_from_provider
    MigrationProvider.reset_column_information
    record = MigrationProvider.find_by(is_default: true) || MigrationProvider.order(:id).first
    return unless record

    self.plugin_settings = plugin_settings.merge(
      "assistant_provider" => record.preset, "assistant_base_url" => record.base_url.to_s,
      "assistant_model" => record.model.to_s, "assistant_api_key_ciphertext" => record.api_key_ciphertext,
      "assistant_auth_style" => record.auth_style.presence || "bearer", "assistant_timeout" => record.timeout,
      "assistant_max_tokens" => record.max_tokens
    ).compact
  end

  def plugin_settings
    Hash(Setting.plugin_openproject_test_management).stringify_keys
  end

  def plugin_settings=(value)
    Setting.plugin_openproject_test_management = value
  end
end
