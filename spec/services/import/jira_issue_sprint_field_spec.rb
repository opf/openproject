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

RSpec.describe Import::JiraIssueSprintField do
  subject(:sprint_field) { described_class.from_client(jira_client) }

  let(:jira_client) { instance_double(Import::JiraClient, fields:) }
  let(:fields) do
    [
      { "id" => "summary", "custom" => false, "schema" => { "type" => "string", "system" => "summary" } },
      { "id" => "customfield_10102", "custom" => true, "schema" => { "custom" => "com.pyxis.greenhopper.jira:gh-sprint" } }
    ]
  end
  let(:jira_import) { create(:jira_import, jira: create(:jira), author: create(:user)) }
  let(:jira_project) { create(:jira_project, jira_import:) }
  let(:issues) { Import::JiraIssue.where(jira_import:) }

  def stage_issue(fields)
    create(:jira_issue, jira_import:, jira_project:, payload: { "fields" => fields })
  end

  describe "#each_issue_sprint_ids" do
    it "yields the project and sprint ids of every issue with sprints" do
      stage_issue("customfield_10102" => [{ "id" => 2 }, { "id" => 1 }])
      stage_issue("customfield_10102" => nil)
      stage_issue("summary" => "No sprint")

      expect { |block| sprint_field.each_issue_sprint_ids(issues, &block) }
        .to yield_successive_args([jira_project.id, %w[2 1]])
    end

    context "when the instance has two sprint fields" do
      let(:fields) do
        %w[customfield_10102 customfield_10200].map do |id|
          { "id" => id, "custom" => true, "schema" => { "custom" => "com.pyxis.greenhopper.jira:gh-sprint" } }
        end
      end

      it "yields every issue once with the distinct sprint ids of both fields" do
        stage_issue("customfield_10102" => [{ "id" => 2 }, { "id" => 2 }], "customfield_10200" => [{ "id" => 2 }, { "id" => 3 }])

        expect { |block| sprint_field.each_issue_sprint_ids(issues, &block) }
          .to yield_successive_args([jira_project.id, %w[2 3]])
      end
    end
  end

  describe ".from_staged_fields" do
    it "reads the sprint field of the staged custom fields" do
      create(:jira_field, jira_import:, origin_id: "customfield_10102", payload: fields.second)
      create(:jira_field, jira_import:, origin_id: "customfield_10300",
                          payload: { "id" => "customfield_10300", "schema" => { "custom" => "other" } })
      issue = stage_issue("customfield_10102" => [{ "id" => 2 }], "customfield_10300" => [{ "id" => 3 }])

      expect(described_class.from_staged_fields(jira_import).current_sprint_id(issue)).to eq("2")
    end
  end

  describe "#current_sprint_id" do
    it "returns nil for an issue without the sprint field" do
      expect(sprint_field.current_sprint_id(stage_issue("summary" => "No sprint"))).to be_nil
    end
  end

  describe "#sprint_ids" do
    it "returns the distinct sprint ids of all issues" do
      stage_issue("customfield_10102" => [{ "id" => 2 }, { "id" => 1 }])
      stage_issue("customfield_10102" => [{ "id" => 2 }])

      expect(sprint_field.sprint_ids(issues)).to eq(%w[2 1])
    end

    context "when the instance has no sprint field" do
      let(:fields) { [{ "id" => "summary", "custom" => false, "schema" => { "type" => "string" } }] }

      it "returns nothing" do
        stage_issue("customfield_10102" => [{ "id" => 2 }])

        expect(sprint_field.sprint_ids(issues)).to eq([])
      end
    end
  end
end
