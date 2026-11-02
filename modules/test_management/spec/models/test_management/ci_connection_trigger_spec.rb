# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::CiConnection, "Run in CI settings (0011)" do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }

  def connection(**attrs) = build(:tm_ci_connection, project:, **attrs)

  describe "providers and repository formats" do
    it "accepts every provider with its repository format" do
      expect(build(:tm_ci_connection, :jenkins, project:)).to be_valid
      expect(build(:tm_ci_connection, :gitea, project:)).to be_valid
      expect(build(:tm_ci_connection, :forgejo, project:)).to be_valid
      expect(build(:tm_ci_connection, :codeberg, project:)).to be_valid
      expect(build(:tm_ci_connection, :woodpecker, project:)).to be_valid
      expect(connection(provider: "jenkins", base_url: "https://j.example.com", repository: "single-job")).to be_valid
    end

    it "rejects wrong repository formats" do
      expect(build(:tm_ci_connection, :woodpecker, project:, repository: "owner/repo")).not_to be_valid
      expect(build(:tm_ci_connection, :gitea, project:, repository: "a/b/c")).not_to be_valid
      expect(build(:tm_ci_connection, :jenkins, project:, repository: "qa/../e2e x")).not_to be_valid
    end

    it "needs a base URL except for github, gitlab and codeberg; HTTPS only" do
      expect(connection(provider: "jenkins", repository: "qa/e2e")).not_to be_valid
      expect(connection(provider: "codeberg", repository: "o/r")).to be_valid
      expect(build(:tm_ci_connection, :gitea, project:, base_url: "http://gitea.example.com")).not_to be_valid
      expect(build(:tm_ci_connection, :codeberg, project:, base_url: "https://codeberg.org").tap(&:valid?).base_url).to be_nil
    end
  end

  it "normalizes workflow paths and validates workflow and ref" do
    record = build(:tm_ci_connection, :github_trigger, project:, workflow: ".github/workflows/e2e.yml",
                                                       trigger_ref: " release/2.4 ")
    expect(record).to be_valid
    expect(record).to have_attributes(workflow: "e2e.yml", trigger_ref: "release/2.4", effective_trigger_ref: "release/2.4")
    expect(build(:tm_ci_connection, :gitea, project:,
                                            workflow: ".forgejo/workflows/op.yaml").tap(&:valid?).workflow).to eq("op.yaml")
    expect(build(:tm_ci_connection, :github_trigger, project:, workflow: "e2e.sh")).not_to be_valid
    expect(build(:tm_ci_connection, :github_trigger, project:, trigger_ref: "main; rm")).not_to be_valid
    expect(build(:tm_ci_connection, project:).effective_trigger_ref).to eq("main")
  end

  describe "#trigger_missing" do
    it "lists what each provider still needs" do
      expect(connection(provider: "github", repository: "o/r").trigger_missing).to eq(%i[workflow token])
      expect(connection(provider: "gitlab", repository: "g/p").trigger_missing).to eq(%i[trigger_token])
      expect(connection(provider: "jenkins", base_url: "https://j.example.com", repository: "e2e").trigger_missing)
        .to eq(%i[ci_username])
      expect(connection(provider: "jenkins", base_url: "https://j.example.com", repository: "e2e", ci_username: "bot")
               .trigger_missing).to eq(%i[token])
      expect(connection(provider: "woodpecker", base_url: "https://ci.example.com", repository: "4").trigger_missing)
        .to eq(%i[token])
    end

    it "is empty for ready connections" do
      %i[github_trigger gitlab_trigger jenkins gitea forgejo codeberg woodpecker].each do |trait|
        expect(build(:tm_ci_connection, trait, project:)).to be_trigger_ready, trait.to_s
      end
      # Jenkins with only a build token (anonymous trigger)
      expect(connection(provider: "jenkins", base_url: "https://j.example.com", repository: "e2e",
                        trigger_token: "build-token")).to be_trigger_ready
    end
  end

  it "builds provider URLs" do
    expect(build(:tm_ci_connection, :jenkins, project:, repository: "qa/e2e").jenkins_job_url)
      .to eq("https://jenkins.example.com/job/qa/job/e2e")
    expect(build(:tm_ci_connection, :codeberg, project:).repository_url).to eq("https://codeberg.org/my-org/shop")
    expect(build(:tm_ci_connection, :woodpecker, project:).repository_url).to eq("https://ci.example.com/repos/42")
  end

  describe "trigger token" do
    it "is stored encrypted, write-only and never serialized" do
      record = create(:tm_ci_connection, :gitlab_trigger, project:)
      expect(record.trigger_token).to be_nil
      expect(record.reload.decrypted_trigger_token).to eq("glptt-trigger-secret")
      expect(record.trigger_token_ciphertext).not_to include("glptt-trigger-secret")
      expect(record.serializable_hash.keys).not_to include("trigger_token_ciphertext")
      expect(record.inspect).not_to include(record.trigger_token_ciphertext)
    end

    it "keeps it on blank input and removes it on request" do
      record = create(:tm_ci_connection, :gitlab_trigger, project:)
      record.update!(trigger_token: "")
      expect(record.reload).to be_trigger_token_set
      record.update!(remove_trigger_token: "1")
      expect(record.reload).not_to be_trigger_token_set
    end

    it "must be entered again when the server changes" do
      record = create(:tm_ci_connection, :gitlab_trigger, project:)
      record.base_url = "https://gitlab.evil.example.com"
      expect(record).not_to be_valid
      expect(record.errors.details[:trigger_token]).to include(error: :reenter_for_new_endpoint)

      record.trigger_token = "glptt-new"
      expect(record).to be_valid
    end
  end
end
