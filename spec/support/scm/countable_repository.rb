require 'open3'
shared_examples_for 'is a countable repository' do
  let(:job) { ::Scm::StorageUpdaterJob.new repository }
  let(:cache_time) { 720 }

  before do
    allow(::Scm::StorageUpdaterJob).to receive(:new).and_return(job)
    allow(Repository).to receive(:find).and_return(repository)
    allow(Setting).to receive(:repository_storage_cache_minutes).and_return(cache_time)
  end
  it 'is countable' do
    expect(repository.scm).to be_storage_available
  end

  context 'with vanished repository' do
    before do
      allow(Repository).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
    end

    it 'does not raise' do
      expect(Rails.logger).to receive(:warn).with(/StorageUpdater requested for Repository/)
      expect { job.perform }.not_to raise_error
    end
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

  describe 'count methods' do
    it 'uses du when available' do
      expect(::Open3).to receive(:capture3).with('du', any_args)
        .and_return(["1234\t.", '', 0])
      expect(repository.scm).not_to receive(:count_storage_fallback)

      expect(repository.scm.count_repository!).to eq(1234)
    end

    it 'falls back to using ruby when du is unavailable' do
      expect(::Open3).to receive(:capture3).with('du', any_args)
        .and_raise(SystemCallError.new 'foo')
      expect(repository.scm).to receive(:count_storage_fallback).and_return(12345)

      expect(repository.scm.count_repository!).to eq(12345)
    end

    it 'falls back to using ruby when du is incompatible' do
      expect(::Open3).to receive(:capture3).with('du', any_args)
        .and_return(['no output', nil, 1])
      expect(repository.scm).to receive(:count_storage_fallback).and_return(12345)

      expect(repository.scm.count_repository!).to eq(12345)
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
