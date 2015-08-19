shared_examples_for 'is a countable repository' do
  let(:job) { ::Scm::StorageUpdaterJob.new repository }
  before do
    allow(::Scm::StorageUpdaterJob).to receive(:new).and_return(job)
    allow(job).to receive(:repository).and_return(repository)
  end
  it 'is countable' do
    expect(repository.scm).to be_storage_available
  end

  context 'with patched counter' do
    let(:count) { 1234 }

    before do
      allow(repository.scm).to receive(:count_repository!).and_return(count)
    end

    it 'has has not been counted initially' do
      expect(repository.required_storage_bytes).to be == 0
      expect(repository.storage_updated_at).to be_nil
    end

    it 'counts the repository storage automatically' do
      expect(repository.required_storage_bytes).to be == 0
      expect(repository.update_required_storage).to be true
      expect(repository.required_storage_bytes).to be == count
      expect(repository.update_required_storage).to be false
      expect(repository.storage_updated_at).to be >= 1.minute.ago
    end

    context 'when latest count is outdated' do
      before do
        allow(repository).to receive(:storage_updated_at).and_return(24.hours.ago)
      end

      it 'sucessfuly updates the count to what the adapter returns' do
        expect(repository.required_storage_bytes).to be == 0
        expect(repository.update_required_storage).to be true
        expect(repository.required_storage_bytes).to be == count
      end
    end
  end

  context 'with real counter' do
    it 'counts the repository storage automatically' do
      expect(repository.required_storage_bytes).to be == 0
      expect(repository.update_required_storage).to be true
      expect(repository.storage_updated_at).to be >= 1.minute.ago
      expect(repository.update_required_storage).to be false
    end
  end
end

shared_examples_for 'is not a countable repository' do
  it 'is not countable' do
    expect(repository.scm).not_to be_storage_available
  end

  it 'does not return or update the count' do
    expect(::Scm::StorageUpdaterJob).not_to receive(:new)
    expect(repository.update_required_storage).to be false
  end
end
