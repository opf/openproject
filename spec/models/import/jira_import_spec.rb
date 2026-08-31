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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Import::JiraImport do
  let(:jira) { create(:jira) }
  let(:author_password) { OpenProject::Passwords::Generator.random_password }
  let(:author) { create(:user, password: author_password, password_confirmation: author_password) }

  subject(:jira_import) { create(:jira_import, jira:, author:) }

  describe "associations" do
    it { is_expected.to belong_to(:jira).class_name("Import::Jira") }
    it { is_expected.to belong_to(:author).class_name("User") }
    it { is_expected.to have_many(:transitions).class_name("Import::JiraImportTransition").dependent(:destroy) }
  end

  describe "#state_machine" do
    it "returns an instance of JiraImportStateMachine" do
      expect(jira_import.state_machine).to be_a(Import::JiraImportStateMachine)
    end

    it "does not memoizes the state machine instance" do
      expect(jira_import.state_machine.object_id).not_to eq(jira_import.state_machine.object_id)
    end
  end

  describe "delegated methods" do
    it { is_expected.to delegate_method(:can_transition_to?).to(:state_machine) }
    it { is_expected.to delegate_method(:current_state).to(:state_machine) }
    it { is_expected.to delegate_method(:history).to(:state_machine) }
    it { is_expected.to delegate_method(:last_transition).to(:state_machine) }
    it { is_expected.to delegate_method(:last_transition_to).to(:state_machine) }
    it { is_expected.to delegate_method(:transition_to!).to(:state_machine) }
    it { is_expected.to delegate_method(:transition_to).to(:state_machine) }
    it { is_expected.to delegate_method(:in_state?).to(:state_machine) }
    it { is_expected.to delegate_method(:running?).to(:state_machine) }
    it { is_expected.to delegate_method(:state_equal_or_after?).to(:state_machine) }
    it { is_expected.to delegate_method(:state_equal_or_before?).to(:state_machine) }
    it { is_expected.to delegate_method(:state_after?).to(:state_machine) }
    it { is_expected.to delegate_method(:state_before?).to(:state_machine) }
    it { is_expected.to delegate_method(:deletable?).to(:state_machine) }
    it { is_expected.to delegate_method(:client).to(:jira) }
  end

  describe "#project_ids" do
    context "when projects is nil" do
      before { jira_import.update_column(:projects, nil) }

      it "returns an empty array" do
        expect(jira_import.project_ids).to eq([])
      end
    end

    context "when projects is empty" do
      before { jira_import.update_column(:projects, []) }

      it "returns an empty array" do
        expect(jira_import.project_ids).to eq([])
      end
    end

    context "when projects contains data" do
      before do
        jira_import.update_column(:projects, [
                                    { "id" => "10001", "name" => "Project A" },
                                    { "id" => "10002", "name" => "Project B" }
                                  ])
      end

      it "returns array of project ids" do
        expect(jira_import.project_ids).to eq(%w[10001 10002])
      end
    end
  end

  describe "#destroy_jira_objects" do
    let!(:jira_project) { create(:jira_project, jira_import:) }
    let!(:jira_field) { create(:jira_field, jira_import:) }
    let!(:jira_issue) { create(:jira_issue, jira_import:, jira_project:) }
    let!(:jira_issue_type) { create(:jira_issue_type, jira_import:) }
    let!(:jira_priority) { create(:jira_priority, jira_import:) }
    let!(:jira_status) { create(:jira_status, jira_import:) }
    let!(:jira_user) { create(:jira_user, jira_import:) }

    it "destroys all associated jira objects" do
      expect { jira_import.destroy_jira_objects }
        .to change(Import::JiraField, :count).by(-1)
        .and change(Import::JiraIssue, :count).by(-1)
        .and change(Import::JiraIssueType, :count).by(-1)
        .and change(Import::JiraPriority, :count).by(-1)
        .and change(Import::JiraProject, :count).by(-1)
        .and change(Import::JiraStatus, :count).by(-1)
        .and change(Import::JiraUser, :count).by(-1)
    end

    it "does not destroy objects from other imports" do
      other_import = create(:jira_import, jira:, author:)
      other_field = create(:jira_field, jira_import: other_import)

      jira_import.destroy_jira_objects

      expect(Import::JiraField.exists?(other_field.id)).to be true
    end
  end
end
