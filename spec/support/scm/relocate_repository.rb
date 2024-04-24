RSpec.shared_examples_for "repository can be relocated" do |vendor|
  let(:job_call) do
    SCM::RelocateRepositoryJob.perform_now repository
  end
  let(:project) { build(:project) }
  let(:repository) do
    repo = build(:"repository_#{vendor}",
                 project:,
                 scm_type: :managed)

    repo.configure(:managed, nil)
    repo.save!
    perform_enqueued_jobs

    repo
  end

  before do
    allow(Repository).to receive(:find).and_return(repository)
  end

  needed_command = "svnadmin" if vendor == :subversion

  context "with managed local config", skip_if_command_unavailable: needed_command do
    include_context "with tmpdir"
    let(:config) { { manages: File.join(tmpdir, "myrepos") } }

    it "relocates when project identifier is updated" do
      current_path = repository.root_url
      expect(repository.root_url).to eq(repository.managed_repository_path)
      expect(Dir.exist?(repository.managed_repository_path)).to be true

      # Rename the project
      project.update!(identifier: "somenewidentifier")
      repository.reload

      job_call

      # Confirm that all paths are updated
      expect(current_path).not_to eq(repository.managed_repository_path)
      expect(current_path).not_to eq(repository.root_url)
      expect(repository.url).to eq(repository.managed_repository_url)

      expect(Dir.exist?(repository.managed_repository_path)).to be true
    end
  end

  context "with managed remote config", :webmock do
    let(:url) { "http://myreposerver.example.com/api/" }
    let(:config) { { manages: url } }

    let(:repository) do
      stub_request(:post, url)
        .to_return(status: 200,
                   body: { success: true, url: "file:///foo/bar", path: "/tmp/foo/bar" }.to_json)
      create(:"repository_#{vendor}",
             project:,
             scm_type: :managed)
    end

    before do
      stub_request(:post, url)
        .to_return(status: 200,
                   body: { success: true, url: "file:///new/bar", path: "/tmp/new/bar" }.to_json)
    end

    it "sends a relocation request when project identifier is updated" do
      old_identifier = "bar"

      # Rename the project
      project.identifier = "somenewidentifier"

      job_call

      expect(WebMock)
        .to have_requested(:post, url)
        .with(body: hash_including(old_identifier:,
                                   action: "relocate"))
    end
  end
end
