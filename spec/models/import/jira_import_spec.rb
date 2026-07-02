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

    it "memoizes the state machine instance" do
      # rubocop:disable RSpec/IdenticalEqualityAssertion
      expect(jira_import.state_machine.object_id).to eq(jira_import.state_machine.object_id)
      # rubocop:enable RSpec/IdenticalEqualityAssertion
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
    it { is_expected.to delegate_method(:status_running?).to(:state_machine) }
    it { is_expected.to delegate_method(:status_equal_or_after?).to(:state_machine) }
    it { is_expected.to delegate_method(:status_equal_or_before?).to(:state_machine) }
    it { is_expected.to delegate_method(:status_after?).to(:state_machine) }
    it { is_expected.to delegate_method(:status_before?).to(:state_machine) }
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
    let!(:jira_field) { create(:jira_field, jira:, jira_import:) }
    let!(:jira_issue) { create(:jira_issue, jira:, jira_import:) }
    let!(:jira_issue_type) { create(:jira_issue_type, jira:, jira_import:) }
    let!(:jira_priority) { create(:jira_priority, jira:, jira_import:) }
    let!(:jira_project) { create(:jira_project, jira:, jira_import:) }
    let!(:jira_status) { create(:jira_status, jira:, jira_import:) }
    let!(:jira_user) { create(:jira_user, jira:, jira_import:) }

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
      other_field = create(:jira_field, jira:, jira_import: other_import)

      jira_import.destroy_jira_objects

      expect(Import::JiraField.exists?(other_field.id)).to be true
    end
  end

  describe "#import_users", with_settings: {
    password_active_rules: %w(lowercase uppercase numeric special),
    password_min_length: 4
  } do
    def jira_user_payload(name:, display_name:, email:, groups: [], key: "JIRAUSER10000", active: true)
      {
        "key" => key,
        "name" => name,
        "self" => "https://jira-dc.openproject.org/rest/api/2/user?username=#{name}",
        "active" => active,
        "expand" => "groups,applicationRoles",
        "groups" => {
          "size" => groups.size,
          "items" => groups.map { |g| { "name" => g, "self" => "https://jira-dc.openproject.org/rest/api/2/group?groupname=#{g}" } }
        },
        "locale" => "en_US",
        "deleted" => false,
        "timeZone" => "Europe/Berlin",
        "avatarUrls" => {
          "16x16" => "https://www.gravatar.com/avatar/abc?d=mm&s=16",
          "24x24" => "https://www.gravatar.com/avatar/abc?d=mm&s=24",
          "32x32" => "https://www.gravatar.com/avatar/abc?d=mm&s=32",
          "48x48" => "https://www.gravatar.com/avatar/abc?d=mm&s=48"
        },
        "displayName" => display_name,
        "emailAddress" => email,
        "lastLoginTime" => "2026-03-26T08:49:31+0000",
        "applicationRoles" => { "size" => 1, "items" => [] }
      }
    end

    let(:email) { "jdoe@example.com" }
    let(:existing_user_password) { OpenProject::Passwords::Generator.random_password }

    # creates system user proactively. so, next coming User.count change cases don't count
    # this one as created during #import_users call.
    before { User.system }

    context "when importing a new user without groups" do
      let!(:jira_user) do
        create(:jira_user,
               jira:,
               jira_import:,
               payload: jira_user_payload(
                 key: "JIRAUSER10100",
                 name: "jdoe@example.com",
                 display_name: "John Doe",
                 email:,
                 groups: []
               ))
      end

      it "creates a new OpenProject user" do
        expect { jira_import.import_users }.to change(User, :count).by(1)
      end

      it "creates the user with correct attributes" do
        jira_import.import_users

        user = User.find_by(login: email)
        expect(user).to have_attributes(
          firstname: "John",
          lastname: "Doe",
          mail: email,
          status: "locked"
        )
      end

      it "creates a reference between Jira user and OpenProject user" do
        expect { jira_import.import_users }.to change(Import::JiraOpenProjectReference, :count).by(1)

        reference = Import::JiraOpenProjectReference.last
        expect(reference).to have_attributes(
          jira_entity_id: jira_user.id.to_s,
          jira_entity_class: "Import::JiraUser",
          op_entity_class: "User",
          uses_existing: false
        )
      end
    end

    context "when importing a user that already exists by email" do
      let!(:existing_user) do
        create(:user,
               mail: email,
               password: existing_user_password,
               password_confirmation: existing_user_password,
               login: "login")
      end
      let!(:jira_user) do
        create(:jira_user,
               jira:,
               jira_import:,
               payload: jira_user_payload(
                 key: "JIRAUSER10101",
                 name: "jdoe@example.com",
                 display_name: "John Doe",
                 email:,
                 groups: []
               ))
      end

      it "does not create a new user" do
        expect { jira_import.import_users }.not_to change(User, :count)
      end

      it "creates a reference to the existing user with uses_existing flag" do
        jira_import.import_users

        reference = Import::JiraOpenProjectReference.find_by(jira_entity_id: jira_user.id)
        expect(reference).to have_attributes(
          jira_entity_id: jira_user.id.to_s,
          jira_entity_class: "Import::JiraUser",
          op_entity_id: existing_user.id.to_s,
          op_entity_class: "User",
          uses_existing: true
        )
      end
    end

    context "when importing a user that already exists by login" do
      let(:login) { "login" }
      let!(:existing_user) do
        create(:user,
               mail: "other@example.com",
               password_confirmation: existing_user_password,
               password: existing_user_password,
               login:)
      end
      let!(:jira_user) do
        create(:jira_user,
               jira:,
               jira_import:,
               payload: jira_user_payload(
                 key: "JIRAUSER10102",
                 name: login,
                 display_name: "John Doe",
                 email:,
                 groups: []
               ))
      end

      it "does not create a new user" do
        expect { jira_import.import_users }.not_to change(User, :count)
      end

      it "creates a reference to the existing user with uses_existing flag" do
        jira_import.import_users

        reference = Import::JiraOpenProjectReference.find_by(jira_entity_id: jira_user.id)
        expect(reference).to have_attributes(
          jira_entity_id: jira_user.id.to_s,
          jira_entity_class: "Import::JiraUser",
          op_entity_id: existing_user.id.to_s,
          op_entity_class: "User",
          uses_existing: true
        )
      end
    end

    context "when importing a user with groups" do
      let!(:jira_user) do
        create(:jira_user,
               jira:,
               jira_import:,
               payload: jira_user_payload(
                 key: "JIRAUSER10103",
                 name: "j.roth@openproject.com",
                 display_name: "Judith Roth",
                 email: "j.roth@openproject.com",
                 groups: ["jira-administrators", "jira-software-users"]
               ))
      end

      it "creates the groups" do
        expect { jira_import.import_users }.to change(Group, :count).by(2)

        expect(Group.exists?(name: "jira-administrators")).to be true
        expect(Group.exists?(name: "jira-software-users")).to be true
      end

      it "adds the user to the groups" do
        jira_import.import_users

        user = User.find_by(login: "j.roth@openproject.com")
        expect(user.groups.pluck(:name)).to contain_exactly("jira-administrators", "jira-software-users")
      end

      it "creates references for the groups" do
        jira_import.import_users

        group_references = Import::JiraOpenProjectReference.where(op_entity_class: "Group")
        expect(group_references.count).to eq(2)
        expect(group_references.pluck(:uses_existing)).to all(be false)
      end
    end

    context "when importing a user with an existing group" do
      let!(:existing_group) { create(:group, name: "jira-administrators") }
      let!(:jira_user) do
        create(:jira_user,
               jira:,
               jira_import:,
               payload: jira_user_payload(
                 key: "JIRAUSER10104",
                 name: "j.roth@openproject.com",
                 display_name: "Judith Roth",
                 email: "j.roth@openproject.com",
                 groups: ["jira-administrators"]
               ))
      end

      it "does not create a duplicate group" do
        expect { jira_import.import_users }.not_to change(Group, :count)
      end

      it "adds the user to the existing group" do
        jira_import.import_users

        user = User.find_by(login: "j.roth@openproject.com")
        expect(user.groups).to include(existing_group)
      end

      it "creates a reference with uses_existing flag for the group" do
        jira_import.import_users

        group_reference = Import::JiraOpenProjectReference.find_by(
          op_entity_class: "Group",
          op_entity_id: existing_group.id
        )
        expect(group_reference.uses_existing).to be true
      end
    end

    context "when importing multiple users" do
      let!(:jira_user1) do
        create(:jira_user,
               jira:,
               jira_import:,
               payload: jira_user_payload(
                 key: "JIRAUSER10105",
                 name: "jdoe@example.com",
                 display_name: "John Doe",
                 email: "jdoe@example.com",
                 groups: ["jira-software-users"]
               ))
      end
      let!(:jira_user2) do
        create(:jira_user,
               jira:,
               jira_import:,
               payload: jira_user_payload(
                 key: "JIRAUSER10106",
                 name: "jsmith@example.com",
                 display_name: "Jane Smith",
                 email: "jsmith@example.com",
                 groups: ["jira-software-users"]
               ))
      end

      it "creates all users" do
        expect { jira_import.import_users }.to change(User, :count).by(2)
      end

      it "creates the shared group only once" do
        expect { jira_import.import_users }.to change(Group, :count).by(1)
      end

      it "adds both users to the shared group" do
        jira_import.import_users

        group = Group.find_by(name: "jira-software-users")
        expect(group.users.pluck(:login)).to contain_exactly("jdoe@example.com", "jsmith@example.com")
      end
    end

    context "when user has a single-word display name" do
      let!(:jira_user) do
        create(:jira_user,
               jira:,
               jira_import:,
               payload: jira_user_payload(
                 key: "JIRAUSER10108",
                 name: "admin@example.com",
                 display_name: "Administrator",
                 email: "admin@example.com",
                 groups: []
               ))
      end

      it "uses the name for both firstname and lastname" do
        jira_import.import_users

        user = User.find_by(login: "admin@example.com")
        expect(user).to have_attributes(
          firstname: "Administrator",
          lastname: "Administrator"
        )
      end
    end

    context "when user has a multi-part display name" do
      let!(:jira_user) do
        create(:jira_user,
               jira:,
               jira_import:,
               payload: jira_user_payload(
                 key: "JIRAUSER10109",
                 name: "jvd@example.com",
                 display_name: "Jean Van Der Berg",
                 email: "jvd@example.com",
                 groups: []
               ))
      end

      it "uses all but last word as firstname and last word as lastname" do
        jira_import.import_users

        user = User.find_by(login: "jvd@example.com")
        expect(user).to have_attributes(
          firstname: "Jean Van Der",
          lastname: "Berg"
        )
      end
    end

    context "when importing a jira user without email(can happen in case of LDAP)" do
      let!(:jira_user) do
        create(:jira_user,
               jira:,
               jira_import:,
               payload: jira_user_payload(
                 key: "JIRAUSER10109",
                 name: "jvd@example.com",
                 display_name: "Jean Van Der Berg",
                 email: nil,
                 groups: []
               ))
      end

      it "creates an OpenProject user with unresolvable email" do
        jira_import.import_users

        user = User.find_by(login: "jvd@example.com")
        expect(user.mail).to match(/@noemail.invalid/)
      end
    end
  end
end
