# frozen_string_literal: true

require "spec_helper"

# 0016: provider + server + repository are unique per project; reference names; attached repository.
RSpec.describe TestManagement::CiConnection, "servers and references" do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }

  it "canonicalises the server URL" do
    expect(described_class.canonical_server("HTTPS://Git.Example.com:443/GitLab/")).to eq("https://git.example.com/gitlab")
    expect(described_class.canonical_server("https://git.example.com:8443")).to eq("https://git.example.com:8443")
  end

  it "stores the server URL, also for the default servers" do
    saas = create(:tm_ci_connection, :gitlab, project:, repository: "qa/web/shop")
    expect(saas.server_url).to eq("https://gitlab.com")
  end

  it "allows the same repository on gitlab.com and on a self-hosted GitLab" do
    create(:tm_ci_connection, :gitlab, project:, repository: "qa/web/shop")
    own = build(:tm_ci_connection, :gitlab, project:, repository: "qa/web/shop", base_url: "https://git.example.com/gitlab")

    expect(own).to be_valid
  end

  it "rejects the same repository twice on one server (case and trailing slash ignored)" do
    create(:tm_ci_connection, :gitlab, project:, repository: "qa/web/shop", base_url: "https://git.example.com/gitlab")
    dup = build(:tm_ci_connection, :gitlab, project:, repository: "qa/web/shop", base_url: "https://GIT.example.com/gitlab/")

    expect(dup).not_to be_valid
    expect(dup.errors.details[:repository]).to include(hash_including(error: :taken))
  end

  it "validates the reference name and the e2e mode" do
    expect(build(:tm_ci_connection, project:, reference_name: "api.v2")).to be_valid
    expect(build(:tm_ci_connection, project:, reference_name: "-bad name")).not_to be_valid
    expect(build(:tm_ci_connection, project:, e2e_tests: "sometimes")).not_to be_valid
  end

  it "derives the reference qualifier from the repository, the setting or (Woodpecker) the name" do
    expect(build(:tm_ci_connection, project:, repository: "my-org/shop").reference_qualifier_name).to eq("shop")
    expect(build(:tm_ci_connection, project:, reference_name: "web").reference_qualifier_name).to eq("web")
    expect(described_class.new(provider: "woodpecker", name: "Mobile CI",
                               repository: "12").reference_qualifier_name).to eq("Mobile-CI")
  end

  it "only attaches a repository of its own project" do
    other = create(:project)
    repository = create(:repository_git, project: other)

    connection = build(:tm_ci_connection, project:, scm_repository_id: repository.id)
    expect(connection).not_to be_valid
    expect(connection.errors.details[:scm_repository]).to include(hash_including(error: :invalid))
  end

  it "builds repository browser URLs for an attached repository" do
    repository = create(:repository_git, project:)
    connection = build(:tm_ci_connection, project:, scm_repository: repository)
    base = "#{Setting.protocol}://#{Setting.host_name}/projects/#{project.identifier}/repository"

    expect(connection.scm_file_url("tests/a b.spec.ts",
                                   ref: "abc123")).to eq("#{base}/revisions/abc123/entry/tests/a%20b.spec.ts")
    expect(connection.scm_file_url("tests/a.spec.ts")).to eq("#{base}/entry/tests/a.spec.ts")
    expect(connection.scm_file_url("../etc/passwd")).to be_nil
  end
end
