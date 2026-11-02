# frozen_string_literal: true

require "spec_helper"
require_relative "../../db/migrate/20261031190000_create_tm_assistant_providers"

# 0021: the single provider setting becomes the first saved provider (and back on rollback).
RSpec.describe CreateTmAssistantProviders, type: :model do
  let(:old_settings) do
    TestManagement::Assistant::ProviderConfig.apply(
      { "default_display_prefix" => "TC" },
      "assistant_provider" => "mistral", "assistant_model" => "mistral-small-latest", "assistant_api_key" => "sk-migrate",
      "assistant_timeout" => "90"
    ).first
  end

  def migrate(direction) = ActiveRecord::Migration.suppress_messages { described_class.migrate(direction) }

  before do
    migrate(:down)
    Setting.plugin_openproject_test_management = old_settings
  end

  after do
    migrate(:up) unless ActiveRecord::Base.connection.table_exists?(:tm_assistant_providers)
    TestManagement::AssistantProvider.reset_column_information
    Setting.plugin_openproject_test_management = {}
  end

  it "moves the setting into a default provider, keeps the key encrypted and cleans the setting" do
    migrate(:up)
    TestManagement::AssistantProvider.reset_column_information

    provider = TestManagement::AssistantProvider.sole
    expect(provider).to have_attributes(name: "Mistral", preset: "mistral", model: "mistral-small-latest", timeout: 90,
                                        is_default: true, user_models: [])
    expect(provider.api_key_ciphertext).to eq(old_settings["assistant_api_key_ciphertext"])
    expect(provider.config.api_key).to eq("sk-migrate")
    expect(Setting.plugin_openproject_test_management.to_h.keys).to eq(%w[default_display_prefix])
  end

  it "creates no provider when none was configured" do
    # Only a preset choice and defaults (no model, base URL or key): nothing was set up.
    Setting.plugin_openproject_test_management = { "default_display_prefix" => "TC", "assistant_provider" => "ollama",
                                                   "assistant_timeout" => 30 }
    migrate(:up)

    expect(TestManagement::AssistantProvider.count).to eq(0)
    expect(Setting.plugin_openproject_test_management.to_h.keys).to eq(%w[default_display_prefix])
  end

  it "writes the default provider back on rollback" do
    migrate(:up)
    migrate(:down)

    settings = Setting.plugin_openproject_test_management.to_h
    expect(settings).to include("assistant_provider" => "mistral", "assistant_model" => "mistral-small-latest",
                                "assistant_api_key_ciphertext" => old_settings["assistant_api_key_ciphertext"])
    expect(TestManagement::Assistant::ProviderConfig.new(settings).api_key).to eq("sk-migrate")
  end
end
