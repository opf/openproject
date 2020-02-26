shared_examples_for 'repository can be relocated' do |vendor|
  let(:job_call) do
    ::SCM::RelocateRepositoryJob.perform_now repository
  end
  let(:project) { FactoryBot.build :project }
  let(:repository) {
    repo = FactoryBot.build("repository_#{vendor}".to_sym,
                             project: project,
                             scm_type: :managed)

    repo.configure(:managed, nil)
    repo.save!
    perform_enqueued_jobs

    repo
  }

  before do
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
      project.update!(identifier: 'somenewidentifier')
      repository.reload

      job_call

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
      FactoryBot.create("repository_#{vendor}".to_sym,
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

      job_call

      expect(WebMock)
        .to have_requested(:post, url)
        .with(body: hash_including(old_identifier: old_identifier,
                                   action: 'relocate'))
    end
  end
end
