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

RSpec.describe Import::JiraIssue do
  let(:jira_import) { create(:jira_import, jira: create(:jira), author: create(:user)) }
  let(:jira_project) { create(:jira_project, jira_import:) }

  def create_issue(fields)
    create(:jira_issue, jira_import:, jira_project:, payload: { "fields" => fields })
  end

  describe ".with_field_set" do
    subject(:issues) { described_class.with_field_set("resolutiondate") }

    it "returns issues with a value for the given field" do
      issue = create_issue("resolutiondate" => "2026-09-12T12:18:05.851+0000")

      expect(issues).to contain_exactly(issue)
    end

    it "excludes issues with a null value for the field" do
      create_issue("resolutiondate" => nil)

      expect(issues).to be_empty
    end

    it "excludes issues without the field" do
      create_issue("summary" => "Unresolved")

      expect(issues).to be_empty
    end
  end
end
