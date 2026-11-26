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

RSpec.describe Import::JiraCreateWorkflowsJob do
  let(:jira_import) { create(:jira_import, jira: create(:jira), author: create(:user)) }
  let!(:role) { create(:project_role, name: "JiraMember") }
  let(:imported_type) { create(:type) }
  let!(:other_type) { create(:type) }

  before do
    create_list(:status, 3)
    create(:jira_open_project_reference, jira_import:, op_entity_class: "Type", op_entity_id: imported_type.id,
                                         jira_entity_class: "Import::JiraIssueType")
  end

  def transitions_of(type)
    type.default_variant.workflow.status_transitions.where(role:).pluck(:old_status_id, :new_status_id)
  end

  it "allows the JiraMember role every transition between all statuses on the import's types" do
    allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction).and_call_original

    described_class.perform_now(jira_import.id)

    status_ids = Status.pluck(:id)
    expect(transitions_of(imported_type)).to match_array(status_ids.product(status_ids))
    expect(OpenProject::Mutex).to have_received(:with_advisory_lock_transaction)
      .with(imported_type.default_variant.workflow).once
  end

  it "leaves the workflows of other types alone" do
    described_class.perform_now(jira_import.id)

    expect(transitions_of(other_type)).to be_empty
  end

  context "when it runs again" do
    before { described_class.perform_now(jira_import.id) }

    it "keeps one transition per pair of statuses" do
      expect { described_class.perform_now(jira_import.id) }.not_to change { transitions_of(imported_type).size }
    end
  end
end
