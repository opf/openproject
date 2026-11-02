# frozen_string_literal: true

FactoryBot.define do
  factory :tm_ci_connection, class: "TestManagement::CiConnection" do
    project
    sequence(:name) { |n| "Shop #{n}" }
    provider { "github" }
    sequence(:repository) { |n| "my-org/shop-#{n}" }
    ingest_mode { "new_run" }
    active { true }

    trait :gitlab do
      provider { "gitlab" }
      sequence(:repository) { |n| "group/sub/app-#{n}" }
    end

    trait :new_iteration do
      ingest_mode { "new_iteration" }
      target_run_name { "Smoke" }
    end

    trait :with_token do
      token { "ghp_secret_token_value" }
    end

    # "Run in CI" (0011): connections that are ready to trigger.
    trait :github_trigger do
      repository { "my-org/shop" }
      workflow { "e2e.yml" }
      token { "ghp_trigger_secret" }
    end

    trait :gitlab_trigger do
      provider { "gitlab" }
      repository { "group/sub/app" }
      trigger_token { "glptt-trigger-secret" }
    end

    trait :jenkins do
      provider { "jenkins" }
      base_url { "https://jenkins.example.com" }
      repository { "qa/e2e" }
      ci_username { "op-bot" }
      token { "jenkins-api-secret" }
    end

    trait :gitea do
      provider { "gitea" }
      base_url { "https://gitea.example.com" }
      repository { "my-org/shop" }
      workflow { "op-tests.yml" }
      token { "gitea-secret" }
    end

    trait :forgejo do
      provider { "forgejo" }
      base_url { "https://forgejo.example.com" }
      repository { "my-org/shop" }
      workflow { "op-tests.yml" }
      token { "forgejo-secret" }
    end

    trait :codeberg do
      provider { "codeberg" }
      repository { "my-org/shop" }
      workflow { "op-tests.yml" }
      token { "codeberg-secret" }
    end

    trait :woodpecker do
      provider { "woodpecker" }
      base_url { "https://ci.example.com" }
      repository { "42" }
      token { "woodpecker-secret" }
    end

    # Self-hosted servers (0015): GitLab on a sub-path (relative URL root) and an inbound-only
    # connection (OpenProject never calls the server).
    trait :self_hosted_gitlab do
      provider { "gitlab" }
      base_url { "https://git.example.com/gitlab" }
      repository { "qa/web/shop" }
      trigger_token { "glptt-selfhosted-secret" }
      token { "glpat-selfhosted-secret" }
    end

    trait :inbound_only do
      inbound_only { true }
    end
  end
end
