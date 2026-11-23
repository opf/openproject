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

RSpec.describe Import::JiraProjectsMetaDataJob do
  shared_let(:author) { create(:admin) }

  let(:jira_import) { create(:jira_import, jira: create(:jira), author:, projects: [{ "id" => "10000", "key" => "DPPP" }]) }

  context "when Jira cannot be reached" do
    let(:jira_client) { instance_double(Import::JiraClient) }

    before do
      allow(Import::JiraImportStateMachine).to receive(:enqueued_job_id).and_return("stubbed-job-id")
      allow(Import::JiraClient).to receive(:new).and_return(jira_client)
      allow(jira_client).to receive(:project_statuses).and_raise("Jira answered 500")
      login_as(author)
      %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching].each do |state|
        jira_import.transition_to!(state)
      end

      described_class.perform_now(jira_import.id)
    end

    it "transitions the import to projects_meta_error" do
      expect(jira_import.reload.current_state).to eq("projects_meta_error")
      expect(jira_import.last_transition.metadata).to include("error" => "Jira answered 500")
    end
  end

  context "when GoodJob's concurrency limit is exceeded" do
    let(:job) { described_class.new(jira_import.id) }

    it "retries through GoodJob instead of failing the import" do
      allow(job).to receive(:retry_job)

      job.rescue_with_handler(GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError.new)

      expect(job).to have_received(:retry_job)
    end
  end
end
