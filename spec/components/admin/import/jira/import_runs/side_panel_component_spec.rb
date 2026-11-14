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

RSpec.describe Admin::Import::Jira::ImportRuns::SidePanelComponent, type: :component do
  let(:jira) { create(:jira) }
  let(:jira_import) { create(:jira_import, jira:, author: create(:admin)) }

  before do
    allow(Import::JiraImportStateMachine).to receive(:enqueued_job_id).and_return("stubbed-job-id")
    jira_import.transition_to!(:instance_meta_fetching)
  end

  context "when the connection check stopped the run" do
    before do
      failure = HealthReport::Result.failure(:administrator, :not_administrator, nil)
      report = jira.health_reports.create!(results: [HealthReport::ResultGroup.new(key: :authorization, results: [failure])])
      jira_import.transition_to!(:instance_meta_error, error: "failed", health_report_id: report.id)
      render_inline(described_class.new(jira_import))
    end

    it "shows the failed check under the run status, without a Test connection button" do
      expect(page).to have_text("Run status")
      expect(page).to have_text("Connection check")
      expect(page).to have_text("ERR_NOT_ADMINISTRATOR")
      expect(page).to have_no_button("Test Connection")
    end
  end

  context "when the run failed for another reason" do
    before do
      jira_import.transition_to!(:instance_meta_error, error: "failed")
      render_inline(described_class.new(jira_import))
    end

    it "shows only the run status" do
      expect(page).to have_text("Run status")
      expect(page).to have_no_text("Connection check")
    end
  end
end
