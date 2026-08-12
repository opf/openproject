# frozen_string_literal: true

FactoryBot.define do
  factory :cde_container, class: 'Cde::Container' do
    project
    owner { association(:user) }
    identifier { "PRJ-BIM-Z1-L2-DR-A-#{SecureRandom.hex(2).upcase}" }
    title { 'Test Container' }
    description { 'Test Description' }
    status { :wip }

    trait :shared do
      status { :shared }
    end

    trait :published do
      status { :published }
    end

    trait :archived do
      status { :archived }
    end

    after(:create) do |container|
      # Ensure working revision is created
      container.revisions.create!(
        revision_code: 'P01',
        is_working: true,
        status: :working,
        author: container.owner
      ) unless container.revisions.exists?(is_working: true)
    end
  end

  factory :cde_revision, class: 'Cde::Revision' do
    container
    author { container.owner }
    revision_code { 'P01' }
    status { :working }
    is_working { true }

    trait :published do
      status { :published }
      published_at { Time.now }
    end

    trait :superseded do
      status { :superseded }
      superseded_at { Time.now }
    end
  end

  factory :cde_metadata, class: 'Cde::Metadata' do
    container
    discipline { :architectural }
    container_type { :drawing }
    originator { 'BIM Team' }
    classification { 'A' }
  end

  factory :cde_suitability, class: 'Cde::Suitability' do
    container
    assigner { container.owner }
    code { :s1 }
    reason { 'Initial suitability assignment' }
  end

  factory :cde_audit_event, class: 'Cde::AuditEvent' do
    auditable { association(:cde_container) }
    user { association(:user) }
    action { 'container.created' }
    event_type { 'create' }
    new_state { { status: 'wip' } }
  end
end
