shared_examples_for 'repository can be relocated' do |vendor|
  let(:job) { ::Scm::RelocateRepositoryJob.new repository }
  let(:project) { FactoryGirl.build :project }
  let(:repository) {
    repo = FactoryGirl.build("repository_#{vendor}".to_sym,
                             project: project,
                             scm_type: :managed)

    repo.configure(:managed, nil)
    repo.save!

    repo
  }

  before do
    allow(::Scm::RelocateRepositoryJob).to receive(:new).and_return(job)
    allow(Repository).to receive(:find).and_return(repository)
  end

  context 'with managed local config' do
    include_context 'with tmpdir'
    let(:config) { { manages: File.join(tmpdir, 'myrepos') } }

    it 'relocates when project identifier is updated' do
      current_path = repository.root_url
      expect(repository.root_url).to eq(repository.managed_repository_path)
      expect(Dir.exists?(repository.managed_repository_path)).to be true

      # Rename the project
      project.update_attributes!(identifier: 'somenewidentifier')
      repository.reload

      job.perform

      # Confirm that all paths are updated
      expect(current_path).not_to eq(repository.managed_repository_path)
      expect(current_path).not_to eq(repository.root_url)
      expect(repository.url).to eq(repository.managed_repository_url)

      expect(Dir.exists?(repository.managed_repository_path)).to be true
    end
  end

  context 'with managed remote config', webmock: true do
    let(:url) { 'http://myreposerver.example.com/api/' }
    let(:config) { { manages: url } }

    let(:repository) {
      stub_request(:post, url)
        .to_return(status: 200,
                   body: { success: true, url: 'file:///foo/bar', path: '/tmp/foo/bar' }.to_json)
      FactoryGirl.create("repository_#{vendor}".to_sym,
                         project: project,
                         scm_type: :managed)
    }

    before do
      stub_request(:post, url)
        .to_return(status: 200,
                   body: { success: true, url: 'file:///new/bar', path: '/tmp/new/bar' }.to_json)
    end

    it 'sends a relocation request when project identifier is updated' do
      old_identifier = 'bar'

      # Rename the project
      project.identifier = 'somenewidentifier'
      job.perform

      expect(WebMock)
        .to have_requested(:post, url)
        .with(body: hash_including(old_identifier: old_identifier,
                                   action: 'relocate'))
    end
  end
end
