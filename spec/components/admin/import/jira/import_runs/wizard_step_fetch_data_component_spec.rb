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
end
