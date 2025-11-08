# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bim::IfcModels::IfcModelMetadata, type: :model do
  subject(:metadata) { build(:bim_ifc_model_metadata) }

  describe 'associations' do
    it { is_expected.to belong_to(:ifc_model).class_name('Bim::IfcModels::IfcModel') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:ifc_model_id) }
    it { is_expected.to validate_uniqueness_of(:ifc_model_id) }
    it { is_expected.to validate_numericality_of(:entity_count).is_greater_than_or_equal_to(0).allow_nil }
    it { is_expected.to validate_numericality_of(:geometry_count).is_greater_than_or_equal_to(0).allow_nil }
    it { is_expected.to validate_numericality_of(:estimated_conversion_time).is_greater_than_or_equal_to(0).allow_nil }
    it { is_expected.to validate_numericality_of(:actual_conversion_time).is_greater_than_or_equal_to(0).allow_nil }
  end

  describe 'scopes' do
    let!(:ifc4_metadata) { create(:bim_ifc_model_metadata, ifc_version: 'IFC4') }
    let!(:ifc2x3_metadata) { create(:bim_ifc_model_metadata, ifc_version: 'IFC2X3') }
    let!(:large_model) { create(:bim_ifc_model_metadata, entity_count: 150_000) }
    let!(:small_model) { create(:bim_ifc_model_metadata, entity_count: 5_000) }

    describe '.by_version' do
      it 'filters by IFC version' do
        expect(described_class.by_version('IFC4')).to contain_exactly(ifc4_metadata)
        expect(described_class.by_version('IFC2X3')).to contain_exactly(ifc2x3_metadata)
      end
    end

    describe '.with_entities_count_above' do
      it 'filters models with entity count above threshold' do
        expect(described_class.with_entities_count_above(100_000)).to contain_exactly(large_model)
      end
    end

    describe '.recently_created' do
      it 'orders by created_at descending' do
        expect(described_class.recently_created.first).to eq(large_model)
      end
    end
  end

  describe '#duplicates' do
    let(:checksum) { 'abc123' }
    let!(:original) { create(:bim_ifc_model_metadata, file_checksum: checksum) }
    let!(:duplicate) { create(:bim_ifc_model_metadata, file_checksum: checksum) }
    let!(:unique) { create(:bim_ifc_model_metadata, file_checksum: 'different') }

    it 'returns models with same checksum' do
      expect(original.duplicates).to contain_exactly(duplicate)
      expect(duplicate.duplicates).to contain_exactly(original)
      expect(unique.duplicates).to be_empty
    end
  end

  describe '#duplicate?' do
    let(:checksum) { 'abc123' }
    let!(:original) { create(:bim_ifc_model_metadata, file_checksum: checksum) }
    let!(:duplicate) { create(:bim_ifc_model_metadata, file_checksum: checksum) }
    let(:unique) { create(:bim_ifc_model_metadata, file_checksum: 'different') }

    it 'returns true if duplicates exist' do
      expect(original.duplicate?).to be true
      expect(duplicate.duplicate?).to be true
      expect(unique.duplicate?).to be false
    end
  end

  describe '#building_storeys' do
    let(:metadata) do
      create(:bim_ifc_model_metadata, spatial_structure: {
        'type' => 'IfcProject',
        'children' => [
          {
            'type' => 'IfcBuilding',
            'children' => [
              { 'type' => 'IfcBuildingStorey', 'name' => 'Level 1' },
              { 'type' => 'IfcBuildingStorey', 'name' => 'Level 2' }
            ]
          }
        ]
      })
    end

    it 'extracts all building storeys from spatial structure' do
      storeys = metadata.building_storeys
      expect(storeys.size).to eq(2)
      expect(storeys.map { |s| s['name'] }).to contain_exactly('Level 1', 'Level 2')
    end
  end

  describe '#spaces' do
    let(:metadata) do
      create(:bim_ifc_model_metadata, spatial_structure: {
        'type' => 'IfcBuilding',
        'children' => [
          {
            'type' => 'IfcBuildingStorey',
            'children' => [
              { 'type' => 'IfcSpace', 'name' => 'Room 101' },
              { 'type' => 'IfcSpace', 'name' => 'Room 102' }
            ]
          }
        ]
      })
    end

    it 'extracts all spaces from spatial structure' do
      spaces = metadata.spaces
      expect(spaces.size).to eq(2)
      expect(spaces.map { |s| s['name'] }).to contain_exactly('Room 101', 'Room 102')
    end
  end

  describe '#property_set' do
    let(:metadata) do
      create(:bim_ifc_model_metadata, property_sets: {
        'Pset_WallCommon' => {
          'properties' => {
            'IsExternal' => { 'value' => true }
          }
        }
      })
    end

    it 'returns property set by name' do
      pset = metadata.property_set('Pset_WallCommon')
      expect(pset).to be_present
      expect(pset['properties']['IsExternal']['value']).to be true
    end

    it 'returns nil for non-existent property set' do
      expect(metadata.property_set('NonExistent')).to be_nil
    end
  end

  describe '#total_area' do
    it 'returns total area from quantities' do
      metadata.quantities = { 'total_area' => 5000.0 }
      expect(metadata.total_area).to eq(5000.0)
    end

    it 'returns 0.0 when no total_area' do
      metadata.quantities = {}
      expect(metadata.total_area).to eq(0.0)
    end
  end

  describe '#total_volume' do
    it 'returns total volume from quantities' do
      metadata.quantities = { 'total_volume' => 15000.0 }
      expect(metadata.total_volume).to eq(15000.0)
    end

    it 'returns 0.0 when no total_volume' do
      metadata.quantities = {}
      expect(metadata.total_volume).to eq(0.0)
    end
  end

  describe '#classification' do
    let(:metadata) do
      create(:bim_ifc_model_metadata, classifications: {
        'Uniclass' => [
          { 'code' => 'Ss_25_10_20', 'name' => 'Walls' }
        ]
      })
    end

    it 'returns classification by system' do
      classification = metadata.classification('Uniclass')
      expect(classification).to be_an(Array)
      expect(classification.first['code']).to eq('Ss_25_10_20')
    end

    it 'returns empty array for non-existent system' do
      expect(metadata.classification('OmniClass')).to eq([])
    end
  end

  describe '#material' do
    let(:metadata) do
      create(:bim_ifc_model_metadata, materials: {
        'materials' => [
          { 'name' => 'Concrete', 'density' => 2400 },
          { 'name' => 'Steel', 'density' => 7850 }
        ]
      })
    end

    it 'returns material by name' do
      material = metadata.material('Concrete')
      expect(material).to be_present
      expect(material['density']).to eq(2400)
    end

    it 'returns nil for non-existent material' do
      expect(metadata.material('Wood')).to be_nil
    end
  end

  describe '#validation_passed?' do
    it 'returns true when no errors' do
      metadata.validation_result = { 'errors' => [] }
      expect(metadata.validation_passed?).to be true
    end

    it 'returns false when errors exist' do
      metadata.validation_result = { 'errors' => ['Invalid geometry'] }
      expect(metadata.validation_passed?).to be false
    end
  end

  describe '#complex?' do
    it 'returns true when complexity score > 0.7' do
      metadata.validation_result = { 'complexity_score' => 0.8 }
      expect(metadata.complex?).to be true
    end

    it 'returns false when complexity score <= 0.7' do
      metadata.validation_result = { 'complexity_score' => 0.5 }
      expect(metadata.complex?).to be false
    end
  end

  describe '#conversion_efficiency' do
    it 'returns efficiency ratio when both times are set' do
      metadata.actual_conversion_time = 90
      metadata.estimated_conversion_time = 120
      expect(metadata.conversion_efficiency).to eq(0.75)
    end

    it 'returns nil when times are not set' do
      expect(metadata.conversion_efficiency).to be_nil
    end
  end

  describe '#conversion_faster_than_estimated?' do
    it 'returns true when actual < estimated' do
      metadata.actual_conversion_time = 90
      metadata.estimated_conversion_time = 120
      expect(metadata.conversion_faster_than_estimated?).to be true
    end

    it 'returns false when actual >= estimated' do
      metadata.actual_conversion_time = 130
      metadata.estimated_conversion_time = 120
      expect(metadata.conversion_faster_than_estimated?).to be false
    end
  end

  describe '#complete?' do
    it 'returns true when key fields are present' do
      metadata.ifc_version = 'IFC4'
      metadata.entity_count = 1000
      metadata.spatial_structure = { 'type' => 'IfcProject' }
      expect(metadata.complete?).to be true
    end

    it 'returns false when key fields are missing' do
      metadata.ifc_version = nil
      expect(metadata.complete?).to be false
    end
  end

  describe '#summary' do
    let(:metadata) do
      create(:bim_ifc_model_metadata,
             ifc_version: 'IFC4',
             entity_count: 10000,
             geometry_count: 5000,
             quantities: { 'total_area' => 2000, 'total_volume' => 6000 },
             property_sets: { 'Pset1' => {}, 'Pset2' => {} },
             materials: { 'materials' => [{ 'name' => 'Concrete' }] },
             spatial_structure: {
               'children' => [
                 { 'type' => 'IfcBuildingStorey' },
                 { 'type' => 'IfcSpace' }
               ]
             },
             validation_result: { 'complexity_score' => 0.6, 'warnings' => ['test'] })
    end

    it 'returns comprehensive summary' do
      summary = metadata.summary
      expect(summary[:ifc_version]).to eq('IFC4')
      expect(summary[:entity_count]).to eq(10000)
      expect(summary[:geometry_count]).to eq(5000)
      expect(summary[:total_area]).to eq(2000)
      expect(summary[:total_volume]).to eq(6000)
      expect(summary[:property_set_count]).to eq(2)
      expect(summary[:material_count]).to eq(1)
      expect(summary[:complexity]).to eq(0.6)
      expect(summary[:warnings_count]).to eq(1)
    end
  end
end
