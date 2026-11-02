# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::CiConnection do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }

  describe "changing the endpoint of a connection with a stored token" do
    let(:connection) { create(:tm_ci_connection, project:, token: "ghp_secret_token_value") }

    it "requires the token to be entered again when the base URL changes" do
      connection.base_url = "https://attacker.example"

      expect(connection).not_to be_valid
      expect(connection.errors.details[:token]).to include(error: :reenter_for_new_endpoint)
      expect(connection.errors.full_messages.join).to include("entered again")
    end

    it "requires the token to be entered again when the provider changes" do
      connection.provider = (described_class::PROVIDERS - [connection.provider]).first

      expect(connection).not_to be_valid
      expect(connection.errors.details[:token]).to include(error: :reenter_for_new_endpoint)
    end

    it "accepts the change with a new token or after removing the token" do
      connection.assign_attributes(base_url: "https://ci.example.com", token: "new_token_value")
      expect(connection).to be_valid

      connection.reload.assign_attributes(base_url: "https://ci.example.com", remove_token: "1")
      expect(connection).to be_valid
    end

    it "does not apply to other edits or connections without a token" do
      connection.name = "Renamed"
      expect(connection).to be_valid

      tokenless = create(:tm_ci_connection, project:)
      tokenless.base_url = "https://ci.example.com"
      expect(tokenless).to be_valid
    end
  end

  describe "token" do
    let(:connection) { create(:tm_ci_connection, project:, token: "ghp_secret_token_value") }

    it "stores the token encrypted and decrypts it only on request" do
      expect(connection.token_ciphertext).to start_with("tmv1:")
      expect(connection.token_ciphertext).not_to include("ghp_secret_token_value")
      expect(connection.reload.decrypted_token).to eq("ghp_secret_token_value")
      expect(connection).to be_token_set
      expect(connection.token_updated_at).to be_present
    end

    it "keeps the stored token when a blank value is assigned and removes it with remove_token" do
      connection.update!(token: "")
      expect(connection.reload.decrypted_token).to eq("ghp_secret_token_value")

      connection.update!(remove_token: "1")
      expect(connection.reload).not_to be_token_set
    end

    it "never exposes the token or its ciphertext in JSON, inspect or the raw column dump" do
      expect(connection.as_json).not_to include("token_ciphertext")
      expect(connection.to_json).not_to include("ghp_secret_token_value")
      expect(connection.to_json).not_to include(connection.token_ciphertext)
      expect(connection.inspect).not_to include(connection.token_ciphertext)
      # The readers exist (validation errors on :token need them) but never return the secret.
      expect(connection.token).to be_nil
      expect(connection.trigger_token).to be_nil
    end

    it "reports a tampered ciphertext as unreadable instead of raising" do
      connection.update_column(:token_ciphertext, "tmv1:garbage")

      expect(connection.reload.decrypted_token).to be_nil
      expect(connection).to be_token_set
      expect(connection).not_to be_token_readable
    end
  end

  describe "validations and normalization" do
    it "normalizes repository and base URL" do
      connection = create(:tm_ci_connection, project:, repository: "/my-org/web.git/", base_url: "https://github.com/")

      expect(connection.repository).to eq("my-org/web")
      expect(connection.base_url).to be_nil
      expect(connection.repository_url).to eq("https://github.com/my-org/web")
    end

    it "requires unique names and repositories per project (case-insensitive)" do
      create(:tm_ci_connection, project:, name: "Web", repository: "my-org/web")

      expect(build(:tm_ci_connection, project:, name: "web")).not_to be_valid
      expect(build(:tm_ci_connection, project:, repository: "My-Org/Web")).not_to be_valid
      expect(build(:tm_ci_connection, name: "Web", repository: "my-org/web")).to be_valid # other project
    end

    it "checks the repository format per provider" do
      expect(build(:tm_ci_connection, project:, repository: "just-a-name")).not_to be_valid
      expect(build(:tm_ci_connection, :gitlab, project:, repository: "group/sub/project")).to be_valid
    end

    it "needs a target run for new_iteration and an https base URL" do
      expect(build(:tm_ci_connection, project:, ingest_mode: "new_iteration", target_run_name: "")).not_to be_valid
      expect(build(:tm_ci_connection, :new_iteration, project:)).to be_valid
      expect(build(:tm_ci_connection, :gitlab, project:, base_url: "http://gitlab.example.com")).not_to be_valid
      expect(build(:tm_ci_connection, :gitlab, project:, base_url: "https://user:pw@gitlab.example.com")).not_to be_valid
      expect(build(:tm_ci_connection, :gitlab, project:, base_url: "https://gitlab.example.com")).to be_valid
    end
  end

  describe ".lookup / .detect" do
    let!(:web) { create(:tm_ci_connection, project:, name: "Web", repository: "my-org/web") }
    let!(:mobile) { create(:tm_ci_connection, :gitlab, project:, name: "Mobile", repository: "group/mobile") }

    it "finds by id or name and detects by provider and repository" do
      expect(described_class.lookup(project, web.id.to_s)).to eq(web)
      expect(described_class.lookup(project, "mobile")).to eq(mobile)
      expect(described_class.lookup(project, "other")).to be_nil
      expect(described_class.detect(project, "GitHub", "My-Org/Web")).to eq(web)
      expect(described_class.detect(project, "github", "group/mobile")).to be_nil
    end
  end
end
