# frozen_string_literal: true

FactoryBot.define do
  factory :bim_element_link, class: 'Bim::ElementLink' do
    association :work_package, factory: :work_package
    association :ifc_model, factory: :ifc_model
    association :user, factory: :user

    sequence(:element_id) { |n| "3XlK#{n}Fr$t4X7Zf8NOew3FNr2" }
    element_type { 'IfcWall' }
    sequence(:element_name) { |n| "Element-#{n}" }
    relationship_type { :related_to }
    status { :active }
    element_properties { {} }

    trait :affected_by do
      relationship_type { :affected_by }
      description { 'Element is affected by this issue' }
    end

    trait :responsible_for do
      relationship_type { :responsible_for }
      description { 'Tracking work on this element' }
    end

    trait :depends_on do
      relationship_type { :depends_on }
      description { 'Work package depends on this element' }
    end

    trait :observes do
      relationship_type { :observes }
      description { 'Monitoring element status' }
    end

    trait :completed do
      status { :completed }
    end

    trait :archived do
      status { :archived }
    end

    trait :wall do
      element_type { 'IfcWall' }
      element_name { 'Wall-001' }
      element_properties do
        {
          'type' => 'IfcWall',
          'name' => 'Wall-001',
          'properties' => {
            'LoadBearing' => true,
            'IsExternal' => false,
            'FireRating' => '120min'
          },
          'quantities' => {
            'NetSideArea' => 25.5,
            'Height' => 3.0,
            'Length' => 10.0
          },
          'geometry' => {
            'hash' => 'abc123xyz'
          },
          'spatial_structure' => {
            'building' => 'Main Building',
            'storey' => 'Level 1',
            'space' => 'Room 101'
          }
        }
      end
    end

    trait :door do
      element_type { 'IfcDoor' }
      element_name { 'Door-D001' }
      element_properties do
        {
          'type' => 'IfcDoor',
          'name' => 'Door-D001',
          'properties' => {
            'OverallHeight' => 2.1,
            'OverallWidth' => 0.9,
            'FireRating' => '60min'
          },
          'quantities' => {
            'Area' => 1.89
          },
          'geometry' => {
            'hash' => 'door123xyz'
          }
        }
      end
    end

    trait :window do
      element_type { 'IfcWindow' }
      element_name { 'Window-W001' }
      element_properties do
        {
          'type' => 'IfcWindow',
          'name' => 'Window-W001',
          'properties' => {
            'OverallHeight' => 1.5,
            'OverallWidth' => 1.2
          },
          'quantities' => {
            'Area' => 1.8
          }
        }
      end
    end

    trait :with_location do
      element_properties do
        {
          'spatial_structure' => {
            'building' => 'Main Building',
            'storey' => 'Level 2',
            'space' => 'Room 205'
          },
          'classification' => {
            'system' => 'Uniclass',
            'code' => 'Ss_25_10_20'
          }
        }
      end
    end
  end
end
