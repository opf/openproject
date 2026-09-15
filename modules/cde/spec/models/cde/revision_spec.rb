# frozen_string_literal: true

RSpec.describe Cde::Revision, type: :model do
  describe 'validations' do
    let(:container) { create(:cde_container) }

    subject do
      build(:cde_revision, container: container)
    end

    it { is_expected.to validate_presence_of(:revision_code) }
    it { is_expected.to belong_to(:container).class_name('Cde::Container') }
    it { is_expected.to belong_to(:author).class_name('User').optional }

    context 'revision code format' do
      it 'accepts preliminary format P01' do
        revision = build(:cde_revision, container: container, revision_code: 'P01')
        expect(revision).to be_valid
      end

      it 'accepts preliminary format P01.01' do
        revision = build(:cde_revision, container: container, revision_code: 'P01.01')
        expect(revision).to be_valid
      end

      it 'accepts contractual format C01' do
        revision = build(:cde_revision, container: container, revision_code: 'C01')
        expect(revision).to be_valid
      end

      it 'rejects invalid format' do
        revision = build(:cde_revision, container: container, revision_code: 'INVALID')
        expect(revision).not_to be_valid
        expect(revision.errors[:revision_code]).to include('must match format: P01, P01.01, C01, A01')
      end
    end

    context 'revision code uniqueness' do
      it 'is unique within container' do
        create(:cde_revision, container: container, revision_code: 'P01')
        duplicate = build(:cde_revision, container: container, revision_code: 'P01')
        expect(duplicate).not_to be_valid
      end
    end
  end

  describe 'single working revision invariant' do
    let(:container) { create(:cde_container) }

    it 'deactivates previous working revision when new one is activated' do
      first_revision = container.revisions.first
      expect(first_revision.is_working).to be true

      # Create a new working revision
      second_revision = create(:cde_revision, container: container, is_working: true)

      # First revision should be deactivated
      first_revision.reload
      expect(first_revision.is_working).to be false
      expect(second_revision.is_working).to be true
    end
  end

  describe 'class methods' do
    let(:container) { create(:cde_container) }

    describe '.active' do
      it 'returns non-superseded revisions' do
        create(:cde_revision, container: container, status: :working)
        create(:cde_revision, container: container, status: :superseded)

        active = Cde::Revision.active(container)
        expect(active.count).to eq(1)
        expect(active.first.status).to eq('working')
      end
    end

    describe '.current_working' do
      it 'returns the active working revision' do
        working = create(:cde_revision, container: container, is_working: true, status: :working)
        create(:cde_revision, container: container, is_working: false, status: :working)

        current = Cde::Revision.current_working(container)
        expect(current).to eq([working])
      end
    end

    describe '.published' do
      it 'returns published revisions ordered by published_at desc' do
        old_pub = create(:cde_revision, container: container, status: :published, published_at: 1.day.ago)
        new_pub = create(:cde_revision, container: container, status: :published, published_at: 1.hour.ago)

        published = Cde::Revision.published(container)
        expect(published).to eq([new_pub, old_pub])
      end
    end
  end
end
