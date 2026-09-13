# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bim::FederationModel, type: :model do
  let(:project) { create(:project) }
  let(:federation) { create(:bim_model_federation, project: project) }
  let(:ifc_model) { create(:bim_ifc_model, project: project) }
  let(:federation_model) { create(:bim_federation_model, model_federation: federation, ifc_model: ifc_model) }

  describe 'associations' do
    it { is_expected.to belong_to(:model_federation) }
    it { is_expected.to belong_to(:ifc_model) }
  end

  describe 'validations' do
    subject { build(:bim_federation_model) }

    it { is_expected.to validate_presence_of(:discipline) }
    it { is_expected.to validate_numericality_of(:opacity).is_greater_than_or_equal_to(0.0).is_less_than_or_equal_to(1.0) }
    it { is_expected.to validate_numericality_of(:display_order).only_integer.is_greater_than_or_equal_to(0) }

    it 'validates uniqueness of ifc_model_id scoped to model_federation_id' do
      existing = create(:bim_federation_model)
      duplicate = build(:bim_federation_model,
                        model_federation: existing.model_federation,
                        ifc_model: existing.ifc_model)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:ifc_model_id]).to be_present
    end

    it 'validates color format' do
      expect(build(:bim_federation_model, color: '#FF5733')).to be_valid
      expect(build(:bim_federation_model, color: 'invalid')).not_to be_valid
      expect(build(:bim_federation_model, color: nil)).to be_valid
    end
  end

  describe 'enums' do
    it 'defines discipline enum' do
      expect(described_class.disciplines.keys).to include(
        'architectural', 'structural', 'mechanical', 'electrical',
        'plumbing', 'civil', 'landscape', 'other'
      )
    end
  end

  describe 'scopes' do
    describe '.visible' do
      let!(:visible_model) { create(:bim_federation_model, visible: true) }
      let!(:hidden_model) { create(:bim_federation_model, visible: false) }

      it 'returns only visible models' do
        expect(described_class.visible).to include(visible_model)
        expect(described_class.visible).not_to include(hidden_model)
      end
    end

    describe '.for_discipline' do
      let!(:arch_model) { create(:bim_federation_model, discipline: :architectural) }
      let!(:struct_model) { create(:bim_federation_model, discipline: :structural) }

      it 'returns models for specified discipline' do
        expect(described_class.for_discipline(:architectural)).to include(arch_model)
        expect(described_class.for_discipline(:architectural)).not_to include(struct_model)
      end
    end

    describe '.ordered_by_display' do
      let!(:model1) { create(:bim_federation_model, display_order: 2) }
      let!(:model2) { create(:bim_federation_model, display_order: 1) }

      it 'orders by display_order ascending' do
        expect(described_class.ordered_by_display).to eq([model2, model1])
      end
    end
  end

  describe 'callbacks' do
    describe 'set_default_color' do
      it 'sets default color based on discipline on create' do
        fm = create(:bim_federation_model, discipline: :architectural, color: nil)
        expect(fm.color).to eq('#3498DB') # Architectural blue
      end

      it 'does not override explicitly set color' do
        fm = create(:bim_federation_model, discipline: :architectural, color: '#FFFFFF')
        expect(fm.color).to eq('#FFFFFF')
      end
    end
  end

  describe '#transformed_extent' do
    let(:federation_model) do
      create(:bim_federation_model,
             transform: {
               'translation' => [10, 20, 30],
               'rotation' => [0, 0, 0],
               'scale' => [1, 1, 1]
             })
    end

    it 'returns transformed bounding box' do
      extent = federation_model.transformed_extent

      expect(extent).to be_a(Hash)
      expect(extent).to have_key(:min)
      expect(extent).to have_key(:max)
    end
  end

  describe '#to_viewer_config' do
    let(:federation_model) do
      create(:bim_federation_model,
             discipline: :structural,
             visible: true,
             color: '#E74C3C',
             opacity: 0.8,
             display_order: 1)
    end

    it 'exports configuration for viewer' do
      config = federation_model.to_viewer_config

      expect(config[:id]).to eq(federation_model.id)
      expect(config[:ifc_model_id]).to eq(federation_model.ifc_model.id)
      expect(config[:discipline]).to eq('structural')
      expect(config[:visible]).to be true
      expect(config[:color]).to eq('#E74C3C')
      expect(config[:opacity]).to eq(0.8)
      expect(config[:display_order]).to eq(1)
      expect(config[:transform]).to be_a(Hash)
    end
  end

  describe '#transformation_matrix' do
    let(:federation_model) do
      create(:bim_federation_model,
             transform: {
               'translation' => [5, 10, 15],
               'rotation' => [0, 0, 90],
               'scale' => [2, 2, 2]
             })
    end

    it 'returns 4x4 transformation matrix' do
      matrix = federation_model.transformation_matrix

      expect(matrix).to be_an(Array)
      expect(matrix.size).to eq(4)
      expect(matrix[0].size).to eq(4)
      expect(matrix[0][3]).to eq(5) # Translation X
      expect(matrix[1][3]).to eq(10) # Translation Y
      expect(matrix[2][3]).to eq(15) # Translation Z
    end
  end

  describe '#discipline_name' do
    it 'returns human-readable discipline name' do
      fm = build(:bim_federation_model, discipline: :mechanical)
      expect(fm.discipline_name).to eq('Mechanical')
    end
  end

  describe 'DISCIPLINE_COLORS' do
    it 'defines colors for all disciplines' do
      expect(described_class::DISCIPLINE_COLORS).to include(
        architectural: '#3498DB',
        structural: '#E74C3C',
        mechanical: '#2ECC71',
        electrical: '#F39C12',
        plumbing: '#9B59B6'
      )
    end
  end
end
