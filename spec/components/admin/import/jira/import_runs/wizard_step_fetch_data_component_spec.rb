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

require "rails_helper"

RSpec.describe Admin::Import::Jira::ImportRuns::WizardStepFetchDataComponent, type: :component do
  subject(:labels) { described_class.new(jira_import).import_stats_available.pluck(:label) }

  let(:jira_import) { build(:jira_import, jira: build(:jira, exclude_resolution_fields:), available:) }
  let(:exclude_resolution_fields) { false }
  let(:available) do
    {
      "projects" => [{ "id" => "1" }],
      "total_issues" => 128,
      "total_statuses" => 29,
      "total_resolutions" => 4,
      "total_issue_types" => 14,
      "total_users" => 12
    }
  end

  it "lists all labels" do
    expect(labels).to eq(["1 project", "128 issues", "29 statuses", "4 resolutions", "14 types", "12 users"])
  end

  context "when resolution fields are excluded" do
    let(:exclude_resolution_fields) { true }

    it "does not list the resolutions" do
      expect(labels).not_to include("4 resolutions")
    end
  end

  describe "server version warning" do
    shared_let(:author) { create(:admin) }

    let(:jira_import) { create(:jira_import, jira: create(:jira), author:, available:) }
    let(:available) { { "server_info" => server_info } }

    before do
      allow(Import::JiraImportStateMachine).to receive(:enqueued_job_id).and_return("stubbed-job-id")
      jira_import.transition_to!(:instance_meta_fetching)
      jira_import.transition_to!(:instance_meta_done)

      render_inline(described_class.new(jira_import))
    end

    context "with a supported version" do
      let(:server_info) { { "version" => "11.3.3" } }

      it "shows no warning" do
        expect(page).to have_no_css(".Banner--warning")
      end
    end

    context "with an unsupported version" do
      let(:server_info) { { "version" => "7.13.18" } }

      it "warns but lets the import continue" do
        expect(page).to have_css(".Banner--warning",
                                 text: I18n.t(:"admin.jira.server_version.unsupported", version: "7.13.18"))
        expect(page).to have_link(I18n.t(:"admin.jira.run.wizard.sections.fetch_data.button_continue"))
      end
    end

    context "with an unknown version" do
      let(:server_info) { { "serverTitle" => "Jira" } }

      it "warns but lets the import continue" do
        expect(page).to have_css(".Banner--warning", text: I18n.t(:"admin.jira.server_version.unknown"))
        expect(page).to have_link(I18n.t(:"admin.jira.run.wizard.sections.fetch_data.button_continue"))
      end
    end
  end
end
