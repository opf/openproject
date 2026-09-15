# frozen_string_literal: true

FactoryBot.define do
  factory :bim_audit_log, class: 'Bim::AuditLog' do
    association :user
    association :project

    action_type { :model_upload }
    details { { model_id: 1, file_name: 'model.ifc', file_size: 1024 } }
    ip_address { '192.168.1.100' }
    user_agent { 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' }
    request_id { SecureRandom.uuid }
    created_at { Time.current }

    trait :model_upload do
      action_type { :model_upload }
      details { { model_id: 1, file_name: 'architecture.ifc', file_size: 10_485_760 } }
    end

    trait :clash_detection_run do
      action_type { :clash_detection_run }
      details { { clash_count: 15, tolerance: 0.01, disciplines: %w[architecture structure] } }
    end

    trait :api_token_created do
      action_type { :api_token_created }
      details { { token_id: 1, token_name: 'Revit Plugin', scopes: ['read:models', 'write:models'] } }
    end

    trait :api_token_revoked do
      action_type { :api_token_revoked }
      details { { token_id: 1, token_name: 'Revit Plugin', reason: 'Security review' } }
    end

    trait :permission_changed do
      action_type { :permission_changed }
      details { { user_id: 2, old_role: 'member', new_role: 'admin' } }
    end

    trait :data_exported do
      action_type { :data_exported }
      details { { export_type: 'audit_logs', format: 'csv', record_count: 150 } }
    end

    trait :recent do
      created_at { 1.hour.ago }
    end

    trait :old do
      created_at { 2.months.ago }
    end

    trait :security_sensitive do
      action_type { :permission_changed }
      details { { sensitive: true } }
    end
  end

  factory :bim_api_token, class: 'Bim::ApiToken' do
    association :user
    association :project

    name { "API Token #{SecureRandom.hex(4)}" }
    description { 'Token for automated access' }
    token_hash { Bim::ApiToken.hash_token(SecureRandom.urlsafe_base64(32)) }
    token_prefix { SecureRandom.hex(4) }
    scopes { ['read:models'] }
    active { true }
    expires_at { nil }
    last_used_at { nil }
    last_used_ip { nil }
    usage_count { 0 }

    trait :with_full_scopes do
      scopes { Bim::ApiToken::AVAILABLE_SCOPES }
    end

    trait :read_only do
      scopes { ['read:models', 'read:clashes', 'read:baselines', 'read:federations', 'read:dashboards'] }
    end

    trait :write_access do
      scopes { ['read:models', 'write:models', 'write:baselines', 'write:federations', 'write:dashboards'] }
    end

    trait :admin_token do
      scopes { ['admin:all'] }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :expiring_soon do
      expires_at { 2.days.from_now }
    end

    trait :long_expiry do
      expires_at { 90.days.from_now }
    end

    trait :never_expires do
      expires_at { nil }
    end

    trait :revoked do
      active { false }
    end

    trait :recently_used do
      last_used_at { 5.minutes.ago }
      last_used_ip { '192.168.1.50' }
      usage_count { 10 }
    end

    trait :heavily_used do
      last_used_at { 1.hour.ago }
      last_used_ip { '192.168.1.75' }
      usage_count { 1500 }
    end

    trait :unused do
      last_used_at { nil }
      last_used_ip { nil }
      usage_count { 0 }
    end

    trait :global_token do
      project { nil }
    end

    trait :project_scoped do
      association :project
    end
  end
end
