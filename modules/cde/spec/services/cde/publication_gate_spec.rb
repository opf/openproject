# frozen_string_literal: true

RSpec.describe Cde::PublicationGate, type: :service do
  describe '.check' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:container) { create(:cde_container, project: project, owner: user) }

    context 'when all preconditions are met' do
      before do
        create(:cde_metadata, container: container, discipline: :architectural,
                              container_type: :drawing, originator: 'BIM Team')
        create(:cde_suitability, container: container, assigner: user, code: :s1)
      end

      it 'returns true' do
        expect(Cde::PublicationGate.check(container)).to be true
      end
    end

    context 'when metadata is incomplete' do
      it 'returns error message' do
        result = Cde::PublicationGate.check(container)
        expect(result).to be_an(Array)
        expect(result).to include('Mandatory metadata incomplete')
      end
    end

    context 'when suitability is not assigned' do
      before do
        create(:cde_metadata, container: container, discipline: :architectural,
                              container_type: :drawing, originator: 'BIM Team')
      end

      it 'returns error message' do
        result = Cde::PublicationGate.check(container)
        expect(result).to be_an(Array)
        expect(result).to include('Suitability not assigned')
      end
    end
  end

  describe '.enforce' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:container) { create(:cde_container, project: project, owner: user) }

    context 'when preconditions are met' do
      before do
        # Set container to shared state first
        container.update!(status: 'shared')
        create(:cde_metadata, container: container, discipline: :architectural,
                              container_type: :drawing, originator: 'BIM Team')
        create(:cde_suitability, container: container, assigner: user, code: :s1)
      end

      it 'publishes the container' do
        expect {
          Cde::PublicationGate.enforce(container, user: user)
        }.to change { container.reload.status }.from('shared').to('published')
      end
    end

    context 'when preconditions are not met' do
      it 'raises PublicationError' do
        expect {
          Cde::PublicationGate.enforce(container, user: user)
        }.to raise_error(Cde::PublicationGate::PublicationError)
      end
    end
  end
end
