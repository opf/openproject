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
  subject(:perform) { described_class.perform_now(jira_import.id) }

  let(:jira) { create(:jira) }
  let(:author) { create(:admin) }
  let(:jira_import) { create(:jira_import, jira:, author:) }

  def imported_user(status: :locked, active_in_jira: true)
    user = create(:user, status:)
    jira_user = create(:jira_user, jira_import:, payload: { "active" => active_in_jira })
    create(:jira_open_project_reference,
           jira_import:,
           op_entity_id: user.id,
           jira_entity_id: jira_user.id)
    user
  end

  before do
    allow(Import::JiraImportStateMachine).to receive(:enqueued_job_id).and_return("stubbed-job-id")
    login_as(author)

    %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching
       projects_meta_done importing imported finalizing].each do |state|
      jira_import.transition_to!(state)
    end
  end

  it "activates the users that are active in Jira and finishes" do
    active_user = imported_user
    inactive_user = imported_user(active_in_jira: false)

    perform

    expect(active_user.reload).to be_active
    expect(inactive_user.reload).to be_locked
    expect(jira_import.reload.current_state).to eq("finalizing_done")
  end

  context "when an imported user was deleted during the review" do
    let!(:remaining_user) { imported_user }

    before { imported_user.destroy }

    it "activates the remaining users and finishes" do
      perform

      expect(remaining_user.reload).to be_active
      expect(jira_import.reload.current_state).to eq("finalizing_done")
    end
  end

  context "when the user limit is reached" do
    before { allow(OpenProject::Enterprise).to receive(:user_limit_reached?).and_return(true) }

    it "fails with the user limit error" do
      imported_user

      perform

      expect(jira_import.reload.current_state).to eq("finalizing_error")
      expect(jira_import.last_transition.metadata["error"])
        .to eq("User limit reached. No more accounts can be created on the current plan.")
    end

    context "when an earlier attempt already activated the users" do
      it "finishes" do
        imported_user(status: :active)

        perform

        expect(jira_import.reload.current_state).to eq("finalizing_done")
      end
    end
  end
end
