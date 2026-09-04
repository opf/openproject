# frozen_string_literal: true

FactoryBot.define do
  factory :bim_section_config, class: 'Bim::SectionConfig' do
    association :ifc_model, factory: :ifc_model
    association :user, factory: :user

    sequence(:name) { |n| "Section Config #{n}" }
    description { 'A section configuration' }

    section_boxes { [] }
    section_planes { [] }

    show_edges { true }
    edge_color { '#000000' }
    show_fills { false }
    fill_color { '#FF0000' }
    fill_opacity { 0.5 }
    is_public { false }

    trait :public_config do
      is_public { true }
    end

    trait :with_box do
      section_boxes do
        [
          {
            'min' => [0.0, 0.0, 0.0],
            'max' => [10.0, 10.0, 10.0],
            'enabled' => true
          }
        ]
      end
    end

    trait :with_multiple_boxes do
      section_boxes do
        [
          {
            'min' => [0.0, 0.0, 0.0],
            'max' => [10.0, 10.0, 10.0],
            'enabled' => true
          },
          {
            'min' => [-5.0, -5.0, -5.0],
            'max' => [5.0, 5.0, 5.0],
            'enabled' => false
          }
        ]
      end
    end

    trait :with_plane do
      section_planes do
        [
          {
            'pos' => [0.0, 0.0, 0.0],
            'dir' => [0.0, 1.0, 0.0],
            'enabled' => true
          }
        ]
      end
    end

    trait :with_multiple_planes do
      section_planes do
        [
          {
            'pos' => [0.0, 0.0, 0.0],
            'dir' => [0.0, 1.0, 0.0],
            'enabled' => true
          },
          {
            'pos' => [10.0, 0.0, 0.0],
            'dir' => [1.0, 0.0, 0.0],
            'enabled' => true
          }
        ]
      end
    end

    trait :floor_cut do
      name { 'Floor 1 Section' }
      section_planes do
        [
          {
            'pos' => [0.0, 1.5, 0.0],
            'dir' => [0.0, 1.0, 0.0],
            'enabled' => true
          }
        ]
      end
    end
  end
end
