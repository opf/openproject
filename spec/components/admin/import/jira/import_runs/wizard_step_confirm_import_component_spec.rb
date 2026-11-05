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

RSpec.describe Admin::Import::Jira::ImportRuns::WizardStepConfirmImportComponent, type: :component do
  subject(:labels) { described_class.new(jira_import).import_selection.pluck(:label) }

  let(:jira_import) do
    build(:jira_import,
          jira: build(:jira, exclude_resolution_fields:),
          projects: [{ "id" => "1" }],
          selected: { "issues_count" => 0, "status_ids" => %w[1 2 3], "issue_type_ids" => %w[1 2] })
  end
  let(:exclude_resolution_fields) { false }
  let(:users_explanation) { "Users that are involved in selected projects (group memberships included)" }
  let(:resolution_statuses_explanation) { 'Additional statuses combining status and resolution (e.g. "Done - Fixed")' }

  it "lists all labels" do
    expect(labels).to eq(["1 project", "0 issues", "3 statuses", "2 types",
                          users_explanation, resolution_statuses_explanation])
  end

  context "when resolution fields are excluded" do
    let(:exclude_resolution_fields) { true }

    it "does not explain the resolution statuses" do
      expect(labels).not_to include(resolution_statuses_explanation)
    end
  end
end
