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

RSpec.describe Import::JiraFinalizeImportJob do
  shared_let(:author) { create(:admin) }

  let(:jira_import) { create(:jira_import, jira: create(:jira), author:) }

  context "when finalizing fails" do
    before do
      allow(Import::JiraImportStateMachine).to receive(:enqueued_job_id).and_return("stubbed-job-id")
      login_as(author)
      %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching
         projects_meta_done importing imported finalizing].each do |state|
        jira_import.transition_to!(state)
      end
      allow(Import::JiraImport).to receive(:find).with(jira_import.id).and_return(jira_import)
      allow(jira_import).to receive(:destroy_jira_objects).and_raise("Something went wrong")

      described_class.perform_now(jira_import.id)
    end

    it "transitions the import to finalizing_error" do
      expect(jira_import.reload.current_state).to eq("finalizing_error")
      expect(jira_import.last_transition.metadata).to include("error" => "Something went wrong")
    end
  end
end
