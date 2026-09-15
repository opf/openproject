# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bim::ModelFederation, type: :model do
  let(:project) { create(:project) }
  let(:ifc_model1) { create(:bim_ifc_model, project: project, title: 'Architectural Model') }
  let(:ifc_model2) { create(:bim_ifc_model, project: project, title: 'Structural Model') }
  let(:federation) { create(:bim_model_federation, project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:federation_models).dependent(:destroy) }
    it { is_expected.to have_many(:ifc_models).through(:federation_models) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_inclusion_of(:units).in_array(%w[meters feet millimeters]).allow_blank }
  end

  describe 'scopes' do
    describe '.for_project' do
      let(:other_project) { create(:project) }
      let!(:federation1) { create(:bim_model_federation, project: project) }
      let!(:federation2) { create(:bim_model_federation, project: other_project) }

      it 'returns federations for the specified project' do
        expect(described_class.for_project(project.id)).to include(federation1)
        expect(described_class.for_project(project.id)).not_to include(federation2)
      end
    end

    describe '.ordered' do
      let!(:federation1) { create(:bim_model_federation, project: project, created_at: 2.days.ago) }
      let!(:federation2) { create(:bim_model_federation, project: project, created_at: 1.day.ago) }

      it 'orders federations by created_at descending' do
        expect(described_class.ordered).to eq([federation2, federation1])
      end
    end
  end

  describe '#load_all_models' do
    before do
      create(:bim_federation_model, model_federation: federation, ifc_model: ifc_model1)
      create(:bim_federation_model, model_federation: federation, ifc_model: ifc_model2)
    end

    it 'returns completed IFC models' do
      ifc_model1.update(conversion_status: :completed)
      ifc_model2.update(conversion_status: :pending)

      expect(federation.load_all_models).to include(ifc_model1)
      expect(federation.load_all_models).not_to include(ifc_model2)
    end
  end

  describe '#models_by_discipline' do
    before do
      create(:bim_federation_model, model_federation: federation, ifc_model: ifc_model1, discipline: :architectural)
      create(:bim_federation_model, model_federation: federation, ifc_model: ifc_model2, discipline: :structural)
    end

    it 'groups federation models by discipline' do
      grouped = federation.models_by_discipline

      expect(grouped.keys).to contain_exactly('architectural', 'structural')
      expect(grouped['architectural'].size).to eq(1)
      expect(grouped['structural'].size).to eq(1)
    end
  end

  describe '#spatial_extent' do
    context 'with no federation models' do
      it 'returns default extent' do
        extent = federation.spatial_extent
        expect(extent[:min]).to eq([0, 0, 0])
        expect(extent[:max]).to eq([10, 10, 10])
      end
    end

    context 'with federation models' do
      let!(:federation_model) do
        create(:bim_federation_model,
               model_federation: federation,
               ifc_model: ifc_model1)
      end

      it 'calculates combined extent' do
        allow(federation_model).to receive(:transformed_extent).and_return({
                                                                              min: [0, 0, 0],
                                                                              max: [20, 20, 20]
                                                                            })

        extent = federation.spatial_extent
        expect(extent[:min]).to eq([0, 0, 0])
        expect(extent[:max]).to eq([20, 20, 20])
      end
    end
  end

  describe '#viewer_config' do
    before do
      federation.update(
        base_point: { x: 100, y: 200, z: 0 },
        rotation: { x: 0, y: 0, z: 90 },
        units: 'meters'
      )
      create(:bim_federation_model, model_federation: federation, ifc_model: ifc_model1)
    end

    it 'returns viewer configuration hash' do
      config = federation.viewer_config

      expect(config[:federation_id]).to eq(federation.id)
      expect(config[:name]).to eq(federation.name)
      expect(config[:base_point]).to eq({ x: 100, y: 200, z: 0 })
      expect(config[:rotation]).to eq({ x: 0, y: 0, z: 90 })
      expect(config[:units]).to eq('meters')
      expect(config[:models]).to be_an(Array)
    end
  end

  describe '#statistics' do
    before do
      create(:bim_federation_model,
             model_federation: federation,
             ifc_model: ifc_model1,
             discipline: :architectural,
             visible: true)
      create(:bim_federation_model,
             model_federation: federation,
             ifc_model: ifc_model2,
             discipline: :structural,
             visible: false)
    end

    it 'returns federation statistics' do
      stats = federation.statistics

      expect(stats[:model_count]).to eq(2)
      expect(stats[:visible_models]).to eq(1)
      expect(stats[:disciplines]).to be_a(Hash)
    end
  end
end
