# frozen_string_literal: true

require "spec_helper"

# Self-hosted servers (0015): merge requests of a GitLab on a sub-path, older GitLab without
# /diffs, inbound-only connections.
RSpec.describe TestManagement::Assistant::Sources::PullRequest, "self-hosted", :disable_ssrf_filter, :webmock do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:gitlab) { create(:tm_ci_connection, :self_hosted_gitlab, project:, name: "Internal GL") }

  let(:mr_url) { "https://git.example.com/gitlab/qa/web/shop/-/merge_requests/7" }
  let(:api) { "https://git.example.com/gitlab/api/v4/projects/qa%2Fweb%2Fshop/merge_requests/7" }

  def source(url) = described_class.new(project:, url:)

  it "matches MR URLs below the relative URL root (with and without /-/ and tab suffixes)" do
    expect(source(mr_url).match).to eq([gitlab, 7])
    expect(source("#{mr_url}/diffs?view=inline").match).to eq([gitlab, 7])
    expect(source("https://git.example.com/gitlab/qa/web/shop/merge_requests/7").match).to eq([gitlab, 7])
    expect(source("https://git.example.com/qa/web/shop/-/merge_requests/7").match).to be_nil
  end

  it "fetches the MR and its diffs through the sub-path API" do
    stub_request(:get, api).with(headers: { "PRIVATE-TOKEN" => "glpat-selfhosted-secret" })
      .to_return(status: 200, body: { title: "Internal MR", description: "Body" }.to_json)
    stub_request(:get, "#{api}/diffs?per_page=100")
      .to_return(status: 200, body: [{ old_path: "a.rb", new_path: "a.rb", diff: "+self hosted" }].to_json)

    expect(source(mr_url).material.text).to include("Internal MR", "+self hosted")
  end

  it "falls back to /changes on GitLab older than 15.7" do
    stub_request(:get, api).to_return(status: 200, body: { title: "Old MR", description: "" }.to_json)
    stub_request(:get, "#{api}/diffs?per_page=100").to_return(status: 404)
    stub_request(:get, "#{api}/changes")
      .to_return(status: 200, body: { changes: [{ old_path: "b.rb", new_path: "b.rb", diff: "+legacy" }] }.to_json)

    expect(source(mr_url).material.text).to include("Old MR", "+legacy")
  end

  it "never calls an inbound-only server" do
    gitlab.update_columns(inbound_only: true)

    expect { source(mr_url).material }
      .to raise_error(TestManagement::Assistant::Sources::Error, /Internal GL.*inbound only/)
    expect(WebMock).not_to have_requested(:any, //)
  ensure
    gitlab.update_columns(inbound_only: false)
  end
end
