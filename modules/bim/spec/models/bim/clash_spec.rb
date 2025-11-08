# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bim::Clash, type: :model do
  subject(:clash) { build(:bim_clash) }

  describe 'associations' do
    it { is_expected.to belong_to(:ifc_model) }
    it { is_expected.to belong_to(:work_package).optional }
    it { is_expected.to belong_to(:assigned_to).optional }
    it { is_expected.to belong_to(:approved_by).optional }
    it { is_expected.to belong_to(:resolved_by).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:element_a_id) }
    it { is_expected.to validate_presence_of(:element_b_id) }
    it { is_expected.to validate_presence_of(:clash_type) }
    it { is_expected.to validate_presence_of(:severity) }
    it { is_expected.to validate_presence_of(:detected_at) }

    it 'validates elements are different' do
      clash.element_a_id = 'wall-1'
      clash.element_b_id = 'wall-1'
      expect(clash).not_to be_valid
      expect(clash.errors[:base]).to include('Element A and Element B must be different')
    end
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:clash_type).with_values(hard: 0, soft: 1, clearance: 2, workflow: 3) }
    it { is_expected.to define_enum_for(:severity).with_values(critical: 0, major: 1, minor: 2) }
    it { is_expected.to define_enum_for(:status).with_values(new: 0, active: 1, approved: 2, resolved: 3, closed: 4) }
  end

  describe 'scopes' do
    let!(:clash_with_wall) { create(:bim_clash, element_a_id: 'wall-1', element_b_id: 'door-1') }
    let!(:clash_with_door) { create(:bim_clash, element_a_id: 'door-1', element_b_id: 'column-1') }
    let!(:resolved_clash) { create(:bim_clash, :resolved) }
    let!(:critical_clash) { create(:bim_clash, :critical) }

    describe '.for_element' do
      it 'finds clashes involving a specific element' do
        expect(described_class.for_element('wall-1')).to contain_exactly(clash_with_wall)
        expect(described_class.for_element('door-1')).to contain_exactly(clash_with_wall, clash_with_door)
      end
    end

    describe '.unresolved' do
      it 'returns only unresolved clashes' do
        expect(described_class.unresolved).not_to include(resolved_clash)
      end
    end

    describe '.needing_attention' do
      it 'returns new and active clashes' do
        results = described_class.needing_attention
        expect(results).not_to include(resolved_clash)
      end
    end
  end

  describe '#normalize_element_order' do
    it 'stores elements in alphabetical order' do
      clash = build(:bim_clash, element_a_id: 'zzz', element_b_id: 'aaa')
      clash.valid?
      expect(clash.element_a_id).to eq('aaa')
      expect(clash.element_b_id).to eq('zzz')
    end
  end

  describe '#approve!' do
    it 'marks clash as approved' do
      user = create(:user)
      expect do
        clash.save!
        clash.approve!(user: user, comment: 'Acceptable')
      end.to change(clash, :status).to('approved')

      expect(clash.approved_by).to eq(user)
      expect(clash.approved_at).to be_present
      expect(clash.approval_comment).to eq('Acceptable')
    end
  end

  describe '#resolve!' do
    it 'marks clash as resolved' do
      clash.save!
      user = create(:user)

      expect do
        clash.resolve!(user: user, resolution_type: :redesign, comment: 'Fixed')
      end.to change(clash, :status).to('resolved')

      expect(clash.resolved_by).to eq(user)
      expect(clash.resolution_type).to eq('redesign')
      expect(clash.resolution_comment).to eq('Fixed')
    end
  end

  describe '#severity_score' do
    it 'calculates score for critical hard clash' do
      clash = build(:bim_clash, :critical, :hard)
      expect(clash.severity_score).to be > 90
    end

    it 'calculates score for minor soft clash' do
      clash = build(:bim_clash, severity: :minor, clash_type: :soft)
      expect(clash.severity_score).to be < 30
    end
  end

  describe '#create_work_package!' do
    it 'creates work package for clash resolution' do
      clash.save!

      expect do
        clash.create_work_package!
      end.to change(WorkPackage, :count).by(1)

      expect(clash.work_package).to be_present
      expect(clash.work_package.subject).to include('Resolve clash')
    end
  end
end
