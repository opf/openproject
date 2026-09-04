# frozen_string_literal: true

RSpec.describe Cde::IdentifierValidator, type: :service do
  describe '.valid?' do
    let(:project) { create(:project) }
    let(:valid_id) { 'PRJ-BIM-Z1-L2-DR-A-0001' }
    let(:invalid_id) { 'INVALID' }

    it 'returns true for valid identifier' do
      expect(Cde::IdentifierValidator.valid?(valid_id)).to be true
    end

    it 'returns false for invalid format' do
      expect(Cde::IdentifierValidator.valid?(invalid_id)).to be false
    end

    it 'returns false for blank identifier' do
      expect(Cde::IdentifierValidator.valid?('')).to be false
      expect(Cde::IdentifierValidator.valid?(nil)).to be false
    end

    context 'with project_id' do
      let!(:existing_container) { create(:cde_container, project: project, identifier: valid_id) }

      it 'returns false for duplicate identifier in project' do
        expect(Cde::IdentifierValidator.valid?(valid_id, project.id)).to be false
      end

      it 'returns true for unique identifier in project' do
        unique_id = 'PRJ-BIM-Z1-L2-DR-A-9999'
        expect(Cde::IdentifierValidator.valid?(unique_id, project.id)).to be true
      end
    end
  end
end
