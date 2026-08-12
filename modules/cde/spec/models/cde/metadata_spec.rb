# frozen_string_literal: true

RSpec.describe Cde::Metadata, type: :model do
  describe 'validations' do
    let(:container) { create(:cde_container) }

    subject do
      build(:cde_metadata, container: container)
    end

    it { is_expected.to validate_presence_of(:discipline) }
    it { is_expected.to validate_presence_of(:container_type) }
    it { is_expected.to validate_presence_of(:originator) }
    it { is_expected.to belong_to(:container).class_name('Cde::Container') }
    it { is_expected.to belong_to(:revision).class_name('Cde::Revision').optional }
  end

  describe 'enums' do
    let(:container) { create(:cde_container) }

    it 'accepts valid discipline values' do
      metadata = build(:cde_metadata, container: container, discipline: :architectural)
      expect(metadata).to be_valid
    end

    it 'accepts valid container_type values' do
      metadata = build(:cde_metadata, container: container, container_type: :drawing)
      expect(metadata).to be_valid
    end
  end

  describe 'scope methods' do
    let(:container1) { create(:cde_container) }
    let(:container2) { create(:cde_container) }

    describe '.by_discipline' do
      it 'returns metadata with given discipline' do
        create(:cde_metadata, container: container1, discipline: :architectural)
        create(:cde_metadata, container: container2, discipline: :structural)

        architectural = Cde::Metadata.by_discipline(:architectural)
        expect(architectural.count).to eq(1)
      end
    end

    describe '.by_container_type' do
      it 'returns metadata with given container type' do
        create(:cde_metadata, container: container1, container_type: :drawing)
        create(:cde_metadata, container: container2, container_type: :model)

        drawings = Cde::Metadata.by_container_type(:drawing)
        expect(drawings.count).to eq(1)
      end
    end
  end
end
