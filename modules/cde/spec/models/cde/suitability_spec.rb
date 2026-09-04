# frozen_string_literal: true

RSpec.describe Cde::Suitability, type: :model do
  describe 'validations' do
    let(:container) { create(:cde_container) }
    let(:user) { create(:user) }

    subject do
      build(:cde_suitability, container: container, assigner: user)
    end

    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to belong_to(:container).class_name('Cde::Container') }
    it { is_expected.to belong_to(:assigner).class_name('User') }

    context 'code values' do
      it 'accepts s0' do
        suitability = build(:cde_suitability, container: container, assigner: user, code: :s0)
        expect(suitability).to be_valid
      end

      it 'accepts s1' do
        suitability = build(:cde_suitability, container: container, assigner: user, code: :s1)
        expect(suitability).to be_valid
      end

      it 'accepts s2' do
        suitability = build(:cde_suitability, container: container, assigner: user, code: :s2)
        expect(suitability).to be_valid
      end

      it 'accepts a1' do
        suitability = build(:cde_suitability, container: container, assigner: user, code: :a1)
        expect(suitability).to be_valid
      end

      it 'accepts a2' do
        suitability = build(:cde_suitability, container: container, assigner: user, code: :a2)
        expect(suitability).to be_valid
      end

      it 'accepts d1' do
        suitability = build(:cde_suitability, container: container, assigner: user, code: :d1)
        expect(suitability).to be_valid
      end
    end
  end

  describe 'audit trail' do
    let(:container) { create(:cde_container) }
    let(:user) { create(:user) }

    it 'creates audit event on assignment' do
      expect {
        create(:cde_suitability, container: container, assigner: user, code: :s1)
      }.to change { Cde::AuditEvent.count }.by(1)

      event = Cde::AuditEvent.last
      expect(event.action).to eq('suitability.assigned')
      expect(event.user).to eq(user)
      expect(event.auditable).to eq(container)
    end
  end
end
