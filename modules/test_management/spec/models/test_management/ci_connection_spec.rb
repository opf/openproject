# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe TestManagement::CiConnection do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }

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

    it "never exposes the token or its ciphertext in JSON or inspect" do
      expect(connection.as_json).not_to include("token_ciphertext")
      expect(connection.to_json).not_to include("ghp_secret_token_value")
      expect(connection.to_json).not_to include(connection.token_ciphertext)
      expect(connection.inspect).not_to include(connection.token_ciphertext)
      expect(connection.token).to be_nil
    end

    it "reports a tampered ciphertext as unreadable instead of raising" do
      connection.update_column(:token_ciphertext, "tmv1:garbage")

      expect(connection.reload.decrypted_token).to be_nil
      expect(connection).to be_token_set
      expect(connection).not_to be_token_readable
    end
  end

  describe "validations and normalization" do
    it "normalizes repository, workflow and trigger ref" do
      connection = create(:tm_ci_connection, project:, repository: "/my-org/web.git/",
                                             workflow: ".github/workflows/e2e.yml", trigger_ref: " ")

      expect(connection.repository).to eq("my-org/web")
      expect(connection.workflow).to eq("e2e.yml")
      expect(connection.trigger_ref).to be_nil
      expect(connection.effective_trigger_ref).to eq("main")
      expect(connection.repository_url).to eq("https://github.com/my-org/web")
    end

    it "requires unique names and repositories per project (case-insensitive)" do
      create(:tm_ci_connection, project:, name: "Web", repository: "my-org/web")

      expect(build(:tm_ci_connection, project:, name: "web")).not_to be_valid
      expect(build(:tm_ci_connection, project:, repository: "My-Org/Web")).not_to be_valid
      expect(build(:tm_ci_connection, name: "Web", repository: "my-org/web")).to be_valid
    end

    it "only accepts github and an owner/repository" do
      expect(build(:tm_ci_connection, project:, provider: "gitlab")).not_to be_valid
      expect(build(:tm_ci_connection, project:, repository: "just-a-name")).not_to be_valid
      expect(build(:tm_ci_connection, project:, repository: "group/sub/project")).not_to be_valid
    end

    it "needs a target run for new_iteration" do
      expect(build(:tm_ci_connection, project:, ingest_mode: "new_iteration", target_run_name: "")).not_to be_valid
      expect(build(:tm_ci_connection, :new_iteration, project:)).to be_valid
    end

    it "validates the workflow file and trigger ref" do
      expect(build(:tm_ci_connection, project:, workflow: "e2e.txt")).not_to be_valid
      expect(build(:tm_ci_connection, project:, trigger_ref: "bad ref")).not_to be_valid
    end
  end

  describe "trigger readiness" do
    it "needs a workflow and a token" do
      expect(build(:tm_ci_connection, project:).trigger_missing).to contain_exactly(:workflow, :token)
      expect(build(:tm_ci_connection, :github_trigger, project:)).to be_trigger_ready
    end
  end

  describe ".lookup / .detect" do
    let!(:web) { create(:tm_ci_connection, project:, name: "Web", repository: "my-org/web") }
    let!(:mobile) { create(:tm_ci_connection, project:, name: "Mobile", repository: "my-org/mobile") }

    it "finds by id or name and detects by provider and repository" do
      expect(described_class.lookup(project, web.id.to_s)).to eq(web)
      expect(described_class.lookup(project, "mobile")).to eq(mobile)
      expect(described_class.lookup(project, "other")).to be_nil
      expect(described_class.detect(project, "GitHub", "My-Org/Web")).to eq(web)
      expect(described_class.detect(project, "gitlab", "my-org/web")).to be_nil
    end
  end
end
