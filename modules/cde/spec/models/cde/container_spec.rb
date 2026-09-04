# frozen_string_literal: true

RSpec.describe Cde::Container, type: :model do
  describe 'validations' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }

    subject do
      build(:cde_container, project: project, owner: user)
    end

    it { is_expected.to validate_presence_of(:identifier) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to belong_to(:project).class_name('Project') }
    it { is_expected.to belong_to(:owner).class_name('User').optional }

    context 'identifier uniqueness' do
      it 'is unique within project' do
        create(:cde_container, project: project, identifier: 'PRJ-BIM-001')
        duplicate = build(:cde_container, project: project, identifier: 'PRJ-BIM-001')
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:identifier]).to include('has already been taken')
      end
    end

    context 'identifier format' do
      it 'accepts valid format' do
        container = build(:cde_container, project: project, identifier: 'PRJ-BIM-Z1-L2-DR-A-0001')
        expect(container).to be_valid
      end

      it 'rejects invalid format' do
        container = build(:cde_container, project: project, identifier: 'INVALID')
        expect(container).not_to be_valid
        expect(container.errors[:identifier]).to include('does not match project convention')
      end
    end
  end

  describe 'associations' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:container) { create(:cde_container, project: project, owner: user) }

    it { is_expected.to have_many(:revisions).class_name('Cde::Revision').dependent(:destroy) }
    it { is_expected.to have_one(:working_revision).class_name('Cde::Revision') }
    it { is_expected.to have_one(:latest_published_revision).class_name('Cde::Revision') }
    it { is_expected.to have_many(:metadata_entries).class_name('Cde::Metadata').dependent(:destroy) }
    it { is_expected.to have_many(:audit_events).class_name('Cde::AuditEvent').as(:auditable).dependent(:destroy) }
    it { is_expected.to have_one(:suitability).class_name('Cde::Suitability').dependent(:destroy) }
  end

  describe 'initialization' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }

    it 'creates initial working revision on create' do
      container = build(:cde_container, project: project, owner: user)
      container.save!

      expect(container.revisions.count).to eq(1)
      expect(container.working_revision).not_to be_nil
      expect(container.working_revision.revision_code).to eq('P01')
      expect(container.working_revision.is_working).to be true
      expect(container.working_revision.status).to eq('working')
    end

    it 'sets working revision author to container owner' do
      container = build(:cde_container, project: project, owner: user)
      container.save!

      expect(container.working_revision.author).to eq(user)
    end
  end

  describe 'class methods' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }

    describe '.by_status' do
      it 'returns containers with given status' do
        create(:cde_container, project: project, status: :wip)
        create(:cde_container, project: project, status: :shared)
        create(:cde_container, project: project, status: :wip)

        wip_containers = Cde::Container.by_status(:wip)
        expect(wip_containers.count).to eq(2)
      end
    end

    describe '.published' do
      it 'returns published containers' do
        create(:cde_container, project: project, status: :published)
        create(:cde_container, project: project, status: :wip)

        published = Cde::Container.published
        expect(published.count).to eq(1)
        expect(published.first.status).to eq('published')
      end
    end

    describe '.search' do
      it 'searches by query' do
        create(:cde_container, project: project, title: 'Foundation Design')
        create(:cde_container, project: project, title: 'Structural Analysis')

        results = Cde::Container.search('Foundation')
        expect(results.count).to eq(1)
        expect(results.first.title).to eq('Foundation Design')
      end
    end
  end

  describe 'status enum' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }

    it 'defaults to wip' do
      container = build(:cde_container, project: project, owner: user)
      expect(container.status).to eq('wip')
    end
  end
end
