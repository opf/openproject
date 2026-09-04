# frozen_string_literal: true

FactoryBot.define do
  factory :bim_ifc_model_metadata, class: 'Bim::IfcModels::IfcModelMetadata' do
    association :ifc_model, factory: :bim_ifc_model

    ifc_version { 'IFC4' }
    file_schema { 'IFC4_ADD2' }
    file_checksum { SecureRandom.hex(32) }
    entity_count { 50_000 }
    geometry_count { 25_000 }

    spatial_structure do
      {
        'type' => 'IfcProject',
        'name' => 'Sample Project',
        'children' => [
          {
            'type' => 'IfcBuilding',
            'name' => 'Building A',
            'children' => [
              {
                'type' => 'IfcBuildingStorey',
                'name' => 'Ground Floor'
              }
            ]
          }
        ]
      }
    end

    property_sets do
      {
        'Pset_BuildingCommon' => {
          'properties' => {
            'BuildingID' => { 'value' => 'B001' },
            'YearOfConstruction' => { 'value' => 2020 }
          }
        }
      }
    end

    quantities do
      {
        'total_area' => 5000.0,
        'total_volume' => 15000.0,
        'by_type' => {
          'IfcWall' => { 'count' => 120, 'total_area' => 2000.0 },
          'IfcSlab' => { 'count' => 30, 'total_area' => 3000.0 }
        }
      }
    end

    classifications do
      {
        'Uniclass' => [
          { 'code' => 'Ss_25_10_20', 'name' => 'Walls' }
        ]
      }
    end

    materials do
      {
        'materials' => [
          {
            'name' => 'Concrete',
            'properties' => { 'density' => 2400 }
          },
          {
            'name' => 'Steel',
            'properties' => { 'density' => 7850 }
          }
        ]
      }
    end

    types do
      {
        'IfcWallType' => {
          'count' => 15,
          'types' => [
            { 'name' => 'External Wall 200mm' },
            { 'name' => 'Internal Wall 100mm' }
          ]
        }
      }
    end

    validation_result do
      {
        'warnings' => [],
        'errors' => [],
        'complexity_score' => 0.5
      }
    end

    estimated_conversion_time { 120 }
    actual_conversion_time { nil }

    trait :with_warnings do
      validation_result do
        {
          'warnings' => [
            'Large file detected (500MB). Conversion may take significant time.',
            'Complex geometry found in element #12345.'
          ],
          'errors' => [],
          'complexity_score' => 0.8
        }
      end
    end

    trait :with_errors do
      validation_result do
        {
          'warnings' => [],
          'errors' => ['Invalid STEP format: missing ISO-10303-21 header'],
          'complexity_score' => 0.0
        }
      end
    end

    trait :complex do
      entity_count { 150_000 }
      geometry_count { 75_000 }
      validation_result do
        {
          'warnings' => ['Complex model detected (150000 entities).'],
          'errors' => [],
          'complexity_score' => 0.9
        }
      end
    end

    trait :ifc2x3 do
      ifc_version { 'IFC2X3' }
      file_schema { 'IFC2X3_TC1' }
    end

    trait :completed_conversion do
      estimated_conversion_time { 120 }
      actual_conversion_time { 95 }
    end

    trait :duplicate do
      file_checksum { 'duplicate_checksum_123' }
    end
  end
end
