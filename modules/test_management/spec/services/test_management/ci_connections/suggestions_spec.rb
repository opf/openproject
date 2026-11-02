# frozen_string_literal: true

require "spec_helper"

# Connection form hints from the GitLab integration and the Repositories module (0015). The
# GitLab tables are read only; the parsing is tested directly so the spec does not depend on the
# GitLab integration's factories.
RSpec.describe TestManagement::CiConnections::Suggestions do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }

  subject(:suggestions) { described_class.new(project) }

  it "splits a branch's project URL into server URL (sub-path included) and project path" do
    suggestion = suggestions.send(:branch_suggestion, "https://example.com/gitlab/qa/web/shop", "qa/web")

    expect(suggestion.to_h).to include(provider: "gitlab", base_url: "https://example.com/gitlab", repository: "qa/web/shop")
  end

  it "ignores inconsistent or non-HTTPS rows" do
    expect(suggestions.send(:branch_suggestion, "https://example.com/gitlab/qa/web/shop", "other")).to be_nil
    expect(suggestions.send(:branch_suggestion, "http://example.com/qa/shop", "qa")).to be_nil
    expect(suggestions.send(:branch_suggestion, "https://example.com/qa/shop", nil)).to be_nil
  end

  it "takes the project URL from a merge request URL" do
    suggestion = suggestions.send(:merge_request_suggestion, "https://example.com/gitlab/qa/shop/-/merge_requests/12")

    expect(suggestion.url).to eq("https://example.com/gitlab/qa/shop")
    expect(suggestion.base_url).to be_nil
    expect(suggestions.send(:merge_request_suggestion, "https://example.com/qa/shop/issues/1")).to be_nil
  end

  it "returns nothing when the GitLab integration is not installed" do
    allow(suggestions).to receive(:model?).and_return(false)

    expect(suggestions.gitlab).to eq([])
  end

  it "offers the base URLs of the project's connections" do
    create(:tm_ci_connection, :self_hosted_gitlab, project:)
    allow(suggestions).to receive(:gitlab).and_return([])

    expect(suggestions.base_urls).to eq(["https://git.example.com/gitlab"])
  end

  it "describes the Repositories module repository" do
    # The id is what a connection attaches (scm_repository_id, 0016).
    repository = instance_double(Repository::Git, id: 7, url: "/srv/repositories/git/shop.git")
    allow(repository).to receive(:class).and_return(Repository::Git)
    allow(project).to receive(:repository).and_return(repository)

    expect(suggestions.scm_repository).to eq(id: 7, scm: "Git", url: "/srv/repositories/git/shop.git")
  end
end
