# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::AssistantProvider do
  it "validates a unique name (case-insensitive) and the user models" do
    create(:tm_assistant_provider, name: "Gateway")

    duplicate = build(:tm_assistant_provider, name: "gateway")
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:name]).to be_present

    too_many = build(:tm_assistant_provider, user_models: (1..21).map { "m#{it}" })
    expect(too_many).not_to be_valid
    expect(too_many.errors.full_messages.join).to include("at most 20")
  end

  it "accepts user models as text, one per line or comma separated" do
    provider = build(:tm_assistant_provider, model: "a", user_models: "b\n c ,d\n\nb")

    expect(provider.user_models).to eq(%w[b c d])
    expect(provider.selectable_models).to eq(%w[a b c d])
  end

  it "keeps exactly one default" do
    first = create(:tm_assistant_provider, :default)
    second = create(:tm_assistant_provider)

    second.make_default!
    expect(first.reload.is_default).to be(false)
    expect(described_class.default_provider).to eq(second)

    second.destroy
    described_class.ensure_default!
    expect(first.reload.is_default).to be(true)
  end

  it "builds a config for an offered model only and names it" do
    provider = create(:tm_assistant_provider, name: "Gateway", model: "small", user_models: %w[large])

    expect(provider.config(model: "large").model).to eq("large")
    expect(provider.config(model: "not-offered").model).to eq("small")
    expect(provider.config(model: "large").display_label).to eq("Gateway · large")
    expect(provider.config.provider_id).to eq(provider.id)
    expect(provider.config.api_key).to eq("sk-factory-secret")
  end

  it "never keeps the key in clear text" do
    provider = create(:tm_assistant_provider, api_key: "sk-clear")

    expect(provider.api_key_ciphertext).not_to include("sk-clear")
    expect(provider.attributes.values.join).not_to include("sk-clear")
  end
end

RSpec.describe TestManagement::Assistant::ProviderChoice do
  shared_let(:user) { create(:user) }

  let!(:default) { create(:tm_assistant_provider, :default, name: "Default", model: "d1", user_models: %w[d2]) }
  let!(:other) { create(:tm_assistant_provider, name: "Other", model: "o1") }

  it "uses the default provider and model until the user picks one" do
    choice = described_class.for(user)

    expect([choice.provider, choice.model, choice.value, choice.label]).to eq([default, "d1", "#{default.id}:d1", "Default · d1"])
  end

  it "stores the pick per user and remembers the model per provider" do
    expect(described_class.select!(user, "#{default.id}:d2")).to be(true)
    expect(described_class.select!(user, other.id.to_s)).to be(true)
    expect(described_class.for(user).value).to eq("#{other.id}:o1")

    described_class.select!(user, default.id.to_s)
    expect(described_class.for(user).model).to eq("d1")
    expect(described_class.for(create(:user)).provider).to eq(default)
  end

  it "accepts model names with colons and rejects models that are not offered" do
    default.update!(user_models: %w[llama3.1:8b])

    expect(described_class.select!(user, "#{default.id}:llama3.1:8b")).to be(true)
    expect(described_class.for(user).model).to eq("llama3.1:8b")
    expect(described_class.select!(user, "#{default.id}:secret-model")).to be(false)
    expect(described_class.select!(user, "abc")).to be(false)
    expect(described_class.select!(User.anonymous, default.id.to_s)).to be(false)
  end

  it "falls back when the model is no longer offered" do
    described_class.select!(user, "#{default.id}:d2")
    default.update!(user_models: [])

    expect(described_class.for(user).model).to eq("d1")
  end

  it "uses the choice recorded on a generation" do
    generation = build(:tm_assistant_generation, user:, provider_id: other.id, chosen_model: "o1")

    expect(described_class.for_record(generation).config.display_label).to eq("Other · o1")
  end

  it "falls back to the setting stored before 0021 without saved providers" do
    TestManagement::AssistantProvider.delete_all
    allow(Setting).to receive(:plugin_openproject_test_management)
      .and_return(TestManagement::Assistant::ProviderConfig.apply({}, "assistant_provider" => "ollama",
                                                                      "assistant_model" => "m").first)

    choice = described_class.for(user)
    expect(choice.provider).to be_nil
    expect(choice.config.provider.key).to eq("ollama")
  end
end
