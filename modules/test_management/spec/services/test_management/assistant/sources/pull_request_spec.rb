# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Assistant::Sources::PullRequest, :disable_ssrf_filter, :webmock do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:github) { create(:tm_ci_connection, :github_trigger, project:, name: "GH") }
  shared_let(:gitlab) do
    create(:tm_ci_connection, :gitlab, project:, name: "GL", base_url: "https://gitlab.example.com",
                                       repository: "group/sub/app", token: "glpat-secret")
  end
  shared_let(:gitea) { create(:tm_ci_connection, :gitea, project:, name: "GT", repository: "my-org/tool") }
  shared_let(:other_project_connection) { create(:tm_ci_connection, :github_trigger, repository: "my-org/foreign") }

  def source(url) = described_class.new(project:, url:)

  describe "#match" do
    it "accepts pull/merge request URLs under the project's connections" do
      expect(source("https://github.com/my-org/shop/pull/12/files?diff=split").match).to eq([github, 12])
      expect(source("https://gitlab.example.com/group/sub/app/-/merge_requests/7").match).to eq([gitlab, 7])
      expect(source("https://gitea.example.com/my-org/tool/pulls/3").match).to eq([gitea, 3])
    end

    it "refuses other repositories, other hosts, other projects and non-PR paths" do
      expect(source("https://github.com/my-org/foreign/pull/1").match).to be_nil
      expect(source("https://evil.example.com/my-org/shop/pull/1").match).to be_nil
      expect(source("https://github.com/my-org/shop/issues/1").match).to be_nil
      expect(source("https://github.com/my-org/shop-other/pull/1").match).to be_nil
    end
  end

  describe "#material" do
    it "fetches title, body and diff from GitHub with the connection token" do
      api = "https://api.github.com/repos/my-org/shop/pulls/12"
      stub_request(:get, api).with(headers: { "Accept" => "application/vnd.github+json" })
        .to_return(status: 200, body: { title: "Add password reset", body: "Closes #5" }.to_json)
      stub_request(:get, api).with(headers: { "Accept" => "application/vnd.github.diff" })
        .to_return(status: 200, body: "diff --git a/reset.rb b/reset.rb\n+def reset; end")

      text = source("https://github.com/my-org/shop/pull/12").material.text

      expect(text).to include("Add password reset", "Closes #5", "+def reset; end")
      expect(WebMock).to have_requested(:get, api).with(headers: { "Authorization" => "Bearer ghp_trigger_secret" }).twice
    end

    it "fetches GitLab merge request and diffs" do
      api = "https://gitlab.example.com/api/v4/projects/group%2Fsub%2Fapp/merge_requests/7"
      stub_request(:get, api).to_return(status: 200, body: { title: "MR title", description: "MR body" }.to_json)
      stub_request(:get, "#{api}/diffs?per_page=100")
        .to_return(status: 200, body: [{ old_path: "a.rb", new_path: "a.rb", diff: "+x" }].to_json)

      text = source("https://gitlab.example.com/group/sub/app/-/merge_requests/7").material.text

      expect(text).to include("MR title", "MR body", "+++ a.rb", "+x")
    end

    it "fetches Gitea pull request and .diff" do
      api = "https://gitea.example.com/api/v1/repos/my-org/tool/pulls/3"
      stub_request(:get, api).to_return(status: 200, body: { title: "Gitea PR", body: "" }.to_json)
      stub_request(:get, "#{api}.diff").to_return(status: 200, body: "+gitea change")

      expect(source("https://gitea.example.com/my-org/tool/pulls/3").material.text).to include("Gitea PR", "+gitea change")
    end

    it "reports provider errors without the token and refuses oversized answers" do
      stub_request(:get, "https://api.github.com/repos/my-org/shop/pulls/12")
        .to_return(status: 404, body: "ghp_trigger_secret not found")

      expect { source("https://github.com/my-org/shop/pull/12").material }
        .to raise_error(TestManagement::Assistant::Sources::Error) { |e|
          expect(e.message).to include("GH (github): HTTP 404")
          expect(e.message).not_to include("ghp_trigger_secret")
        }

      stub_request(:get, "https://api.github.com/repos/my-org/shop/pulls/12")
        .to_return(status: 200, body: "x" * (described_class::MAX_BYTES + 1))
      expect { source("https://github.com/my-org/shop/pull/12").material }
        .to raise_error(TestManagement::Assistant::Sources::Error, /too large/)
    end

    it "cuts long diffs" do
      api = "https://api.github.com/repos/my-org/shop/pulls/12"
      stub_request(:get, api).with(headers: { "Accept" => "application/vnd.github+json" }).to_return(status: 200,
                                                                                                     body: { title: "Big" }.to_json)
      stub_request(:get, api).with(headers: { "Accept" => "application/vnd.github.diff" })
        .to_return(status: 200, body: "+" * (described_class::DIFF_CHARS + 500))

      expect(source("https://github.com/my-org/shop/pull/12").material.text).to include("[… truncated]")
    end
  end
end
