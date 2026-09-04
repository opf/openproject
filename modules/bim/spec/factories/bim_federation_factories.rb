# frozen_string_literal: true

FactoryBot.define do
  factory :bim_model_federation, class: 'Bim::ModelFederation' do
    association :project
    sequence(:name) { |n| "Federation #{n}" }
    description { 'A coordinated set of BIM models' }
    base_point { { x: 0, y: 0, z: 0 } }
    rotation { { x: 0, y: 0, z: 0 } }
    units { 'meters' }

    trait :with_models do
      transient do
        model_count { 3 }
      end

      after(:create) do |federation, evaluator|
        create_list(:bim_federation_model, evaluator.model_count, model_federation: federation)
      end
    end

    trait :multi_discipline do
      after(:create) do |federation|
        create(:bim_federation_model, model_federation: federation, discipline: :architectural)
        create(:bim_federation_model, model_federation: federation, discipline: :structural)
        create(:bim_federation_model, model_federation: federation, discipline: :mechanical)
      end
    end

    trait :feet_units do
      units { 'feet' }
    end

    trait :with_offset do
      base_point { { x: 1000, y: 2000, z: 0 } }
      rotation { { x: 0, y: 0, z: 45 } }
    end
  end

  factory :bim_federation_model, class: 'Bim::FederationModel' do
    association :model_federation, factory: :bim_model_federation
    association :ifc_model, factory: :bim_ifc_model

    discipline { :architectural }
    transform do
      {
        'translation' => [0, 0, 0],
        'rotation' => [0, 0, 0],
        'scale' => [1, 1, 1]
      }
    end
    display_order { 0 }
    visible { true }
    color { nil } # Will be set by callback
    opacity { 1.0 }

    trait :architectural do
      discipline { :architectural }
      color { '#3498DB' }
    end

    trait :structural do
      discipline { :structural }
      color { '#E74C3C' }
    end

    trait :mechanical do
      discipline { :mechanical }
      color { '#2ECC71' }
    end

    trait :electrical do
      discipline { :electrical }
      color { '#F39C12' }
    end

    trait :plumbing do
      discipline { :plumbing }
      color { '#9B59B6' }
    end

    trait :hidden do
      visible { false }
    end

    trait :semi_transparent do
      opacity { 0.5 }
    end

    trait :with_transform do
      transform do
        {
          'translation' => [10, 20, 0],
          'rotation' => [0, 0, 90],
          'scale' => [1, 1, 1]
        }
      end
    end

    trait :with_large_offset do
      transform do
        {
          'translation' => [1000, 2000, 500],
          'rotation' => [0, 0, 0],
          'scale' => [1, 1, 1]
        }
      end
    end
  end
end
