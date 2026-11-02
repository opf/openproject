# frozen_string_literal: true

FactoryBot.define do
  factory :tm_assistant_generation, class: "TestManagement::AssistantGeneration" do
    project
    user
    status { "queued" }
    progress_step { "queued" }
    source_type { "text" }
    source { { "text" => "Users can reset their password with a link sent by email." } }
    options { { "count" => "2", "types" => %w[positive negative], "suite_id" => nil, "label_names" => [] } }

    trait :done do
      status { "done" }
      progress_step { "writing_drafts" }
      progress_done { 2 }
      progress_total { 2 }
      usage { { "prompt_tokens" => 120, "completion_tokens" => 80, "total_tokens" => 200 } }
      drafts do
        [
          { "key" => "d1", "title" => "Reset with a valid link", "type" => "positive", "priority" => "high",
            "preconditions" => "A user with a confirmed email exists",
            "steps" => [{ "action" => "Request a reset", "expected_result" => "An email is sent" }] },
          { "key" => "d2", "title" => "Expired link is rejected", "type" => "negative", "priority" => "medium",
            "preconditions" => nil,
            "steps" => [{ "action" => "Open a link older than 30 minutes", "expected_result" => "An error is shown" }] }
        ]
      end
    end

    trait :running do
      status { "running" }
      progress_step { "preparing_source" }
      progress_done { 1 }
      progress_total { 4 }
    end

    trait :failed do
      status { "failed" }
      error { "the answer contained no usable test cases" }
    end

    trait :cancelled do
      status { "cancelled" }
    end
  end

  factory :tm_assistant_message, class: "TestManagement::AssistantMessage" do
    project
    user
    role { "user" }
    state { "done" }
    content { "How many test cases are ready?" }

    trait :answer do
      role { "assistant" }
      content { "There are 3 ready test cases." }
    end

    trait :pending do
      role { "assistant" }
      state { "pending" }
      content { nil }
    end
  end

  # A saved AI provider (0021). The key goes through ProviderConfig.apply, so it is stored encrypted.
  factory :tm_assistant_provider, class: "TestManagement::AssistantProvider" do
    sequence(:name) { |n| "Provider #{n}" }
    preset { "custom" }
    base_url { "https://llm.example.com/v1" }
    model { "test-model" }
    user_models { [] }
    is_default { false }

    transient do
      api_key { "sk-factory-secret" }
    end

    after(:build) do |provider, evaluator|
      merged, errors = TestManagement::Assistant::ProviderConfig.apply(
        {}, "assistant_provider" => provider.preset, "assistant_base_url" => provider.base_url.to_s,
            "assistant_model" => provider.model.to_s, "assistant_api_key" => evaluator.api_key.to_s,
            "assistant_auth_style" => provider.auth_style.presence || (provider.preset == "custom" ? "bearer" : nil)
      )
      raise ArgumentError, errors.join(" ") if errors.any?

      provider.assign_settings(merged)
    end

    trait :default do
      is_default { true }
    end
  end
end
