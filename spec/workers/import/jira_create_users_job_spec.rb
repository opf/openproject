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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Import::JiraCreateUsersJob, with_settings: {
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

  def import_users
    described_class.perform_now(jira_import.id)
  end

  let(:jira) { create(:jira) }
  let(:author_password) { OpenProject::Passwords::Generator.random_password }
  let(:author) { create(:user, password: author_password, password_confirmation: author_password) }
  let(:jira_import) { create(:jira_import, jira:, author:) }

  let(:email) { "jdoe@example.com" }
  let(:existing_user_password) { OpenProject::Passwords::Generator.random_password }

  # creates system user proactively. so, next coming User.count change cases don't count
  # this one as created during the job run.
  before { User.system }

  context "when importing a new user without groups" do
    let!(:jira_user) do
      create(:jira_user,
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
      expect { import_users }.to change(User, :count).by(1)
    end

    it "creates the user with correct attributes" do
      import_users

      user = User.find_by(login: email)
      expect(user).to have_attributes(
        firstname: "John",
        lastname: "Doe",
        mail: email,
        status: "locked"
      )
    end

    it "creates a reference between Jira user and OpenProject user" do
      expect { import_users }.to change(Import::JiraOpenProjectReference, :count).by(1)

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
      expect { import_users }.not_to change(User, :count)
    end

    it "creates a reference to the existing user with uses_existing flag" do
      import_users

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
             jira_import:,
             origin_id: "JIRAUSER10102",
             payload: jira_user_payload(
               key: "JIRAUSER10102",
               name: login,
               display_name: "John Doe",
               email:,
               groups: []
             ))
    end

    it "creates a new user with a unique login" do
      expect { import_users }.to change(User, :count).by(1)
    end

    it "assigns a Jira-key-based login to the new user" do
      import_users

      reference = Import::JiraOpenProjectReference.find_by(jira_entity_id: jira_user.id)
      new_user = User.find(reference.op_entity_id)
      expect(new_user.login).to eq("login+JIRAUSER10102")
      expect(new_user.mail).to eq(email)
    end

    it "marks the reference as not using an existing user" do
      import_users

      reference = Import::JiraOpenProjectReference.find_by(jira_entity_id: jira_user.id)
      expect(reference.uses_existing).to be false
    end

    context "when the Jira-key-based login is already taken" do
      before do
        create(:user,
               login: "login+JIRAUSER10102",
               mail: "another@example.com",
               password: existing_user_password,
               password_confirmation: existing_user_password)
      end

      it "falls back to a counter suffix" do
        import_users

        reference = Import::JiraOpenProjectReference.find_by(jira_entity_id: jira_user.id)
        expect(User.find(reference.op_entity_id).login).to eq("login+JIRAUSER10102+1")
      end
    end
  end

  context "when importing a user with groups" do
    let!(:jira_user) do
      create(:jira_user,
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
      expect { import_users }.to change(Group, :count).by(2)

      expect(Group.exists?(name: "jira-administrators")).to be true
      expect(Group.exists?(name: "jira-software-users")).to be true
    end

    it "adds the user to the groups" do
      import_users

      user = User.find_by(login: "j.roth@openproject.com")
      expect(user.groups.pluck(:name)).to contain_exactly("jira-administrators", "jira-software-users")
    end

    it "creates references for the groups" do
      import_users

      group_references = Import::JiraOpenProjectReference.where(op_entity_class: "Group")
      expect(group_references.count).to eq(2)
      expect(group_references.pluck(:uses_existing)).to all(be false)
    end
  end

  context "when importing a user with an existing group" do
    let!(:existing_group) { create(:group, name: "jira-administrators") }
    let!(:jira_user) do
      create(:jira_user,
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
      expect { import_users }.not_to change(Group, :count)
    end

    it "adds the user to the existing group" do
      import_users

      user = User.find_by(login: "j.roth@openproject.com")
      expect(user.groups).to include(existing_group)
    end

    it "creates a reference with uses_existing flag for the group" do
      import_users

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
      expect { import_users }.to change(User, :count).by(2)
    end

    it "creates the shared group only once" do
      expect { import_users }.to change(Group, :count).by(1)
    end

    it "adds both users to the shared group" do
      import_users

      group = Group.find_by(name: "jira-software-users")
      expect(group.users.pluck(:login)).to contain_exactly("jdoe@example.com", "jsmith@example.com")
    end

    it "creates a single reference for the shared group" do
      expect { import_users }
        .to change { Import::JiraOpenProjectReference.where(op_entity_class: "Group").count }.by(1)
    end

    it "keeps the shared group marked as created by this import" do
      import_users

      reference = Import::JiraOpenProjectReference.find_by(
        op_entity_class: "Group", op_entity_id: Group.find_by(name: "jira-software-users").id
      )
      expect(reference.uses_existing).to be false
    end

    context "when the shared group already exists in OpenProject" do
      let!(:existing_group) { create(:group, name: "jira-software-users") }

      it "does not create a duplicate group" do
        expect { import_users }.not_to change(Group, :count)
      end

      it "keeps the shared group marked as pre-existing" do
        import_users

        reference = Import::JiraOpenProjectReference.find_by(
          op_entity_class: "Group", op_entity_id: existing_group.id
        )
        expect(reference.uses_existing).to be true
      end

      it "adds both users to the existing group" do
        import_users

        expect(existing_group.reload.users.pluck(:login))
          .to contain_exactly("jdoe@example.com", "jsmith@example.com")
      end
    end
  end

  context "when a stopped import run is retried" do
    let!(:jira_user) do
      create(:jira_user,
             jira_import:,
             origin_id: "JIRAUSER10120",
             payload: jira_user_payload(
               key: "JIRAUSER10120",
               name: "jdoe@example.com",
               display_name: "John Doe",
               email:,
               groups: ["jira-software-users"]
             ))
    end

    it "does not create a duplicate OpenProject user" do
      expect { import_users }.to change(User, :count).by(1)
      expect { import_users }.not_to change(User, :count)
      expect { import_users }.not_to change(User, :count)
    end

    it "does not create additional references for the same Jira user" do
      expect { import_users }.to change(Import::JiraOpenProjectReference, :count).by(2)
      expect { import_users }.not_to change(Import::JiraOpenProjectReference, :count)
    end

    it "keeps the reference pointing at the originally imported user" do
      import_users
      reference = Import::JiraOpenProjectReference.find_by(jira_entity_id: jira_user.id,
                                                           jira_entity_class: Import::JiraUser.to_s)

      import_users

      expect(reference.reload).to have_attributes(
        op_entity_id: User.find_by(login: email).id.to_s,
        uses_existing: false
      )
    end

    it "does not suffix the login or email of the imported user" do
      2.times { import_users }

      expect(User.where("login LIKE '%+%'")).to be_empty
      expect(User.find_by(login: email).mail).to eq(email)
    end

    it "keeps the group membership intact" do
      2.times { import_users }

      group = Group.find_by(name: "jira-software-users")
      expect(group.users.pluck(:login)).to contain_exactly(email)
    end

    it "keeps the group marked as created by this import" do
      2.times { import_users }

      group_reference = Import::JiraOpenProjectReference.find_by(
        op_entity_class: "Group",
        op_entity_id: Group.find_by(name: "jira-software-users").id
      )
      expect(group_reference.uses_existing).to be false
    end

    it "does not create additional group references" do
      expect { import_users }
        .to change { Import::JiraOpenProjectReference.where(op_entity_class: "Group").count }.by(1)
      expect { import_users }
        .not_to change { Import::JiraOpenProjectReference.where(op_entity_class: "Group").count }
    end

    context "when the previous attempt reused an existing OpenProject user" do
      let!(:existing_user) do
        create(:user,
               mail: email,
               password: existing_user_password,
               password_confirmation: existing_user_password,
               login: "pre-existing")
      end

      it "does not create a duplicate and keeps the uses_existing flag" do
        expect { import_users }.not_to change(User, :count)
        expect { import_users }.not_to change(User, :count)

        reference = Import::JiraOpenProjectReference.find_by(jira_entity_id: jira_user.id,
                                                             jira_entity_class: Import::JiraUser.to_s)
        expect(reference).to have_attributes(
          op_entity_id: existing_user.id.to_s,
          uses_existing: true
        )
      end
    end
  end

  context "when user has a single-word display name" do
    let!(:jira_user) do
      create(:jira_user,
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
      import_users

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
      import_users

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
      import_users

      user = User.find_by(login: "jvd@example.com")
      expect(user.mail).to match(/@noemail.invalid/)
    end
  end

  context "when two Jira users share the same email address" do
    let(:shared_email) { "shared@example.com" }
    let!(:jira_user1) do
      create(:jira_user,
             jira_import:,
             payload: jira_user_payload(
               key: "JIRAUSER10110",
               name: "user.one",
               display_name: "User One",
               email: shared_email,
               groups: []
             ))
    end
    let!(:jira_user2) do
      create(:jira_user,
             jira_import:,
             origin_id: "JIRAUSER10111",
             payload: jira_user_payload(
               key: "JIRAUSER10111",
               name: "user.two",
               display_name: "User Two",
               email: shared_email,
               groups: []
             ))
    end

    it "creates two separate OpenProject users" do
      expect { import_users }.to change(User, :count).by(2)
    end

    it "creates individual references for each Jira user" do
      import_users

      ref1 = Import::JiraOpenProjectReference.find_by(jira_entity_id: jira_user1.id)
      ref2 = Import::JiraOpenProjectReference.find_by(jira_entity_id: jira_user2.id)

      expect(ref1).to be_present
      expect(ref2).to be_present
      expect(ref1.op_entity_id).not_to eq(ref2.op_entity_id)
    end

    it "keeps the original email for the first imported user" do
      import_users

      ref1 = Import::JiraOpenProjectReference.find_by(jira_entity_id: jira_user1.id)
      expect(User.find(ref1.op_entity_id).mail).to eq(shared_email)
    end

    it "assigns a plus-addressed email using the Jira key of the second imported user" do
      import_users

      ref2 = Import::JiraOpenProjectReference.find_by(jira_entity_id: jira_user2.id)
      expect(User.find(ref2.op_entity_id).mail).to eq("shared+JIRAUSER10111@example.com")
    end

    it "marks the second user as not using an existing OP user" do
      import_users

      ref2 = Import::JiraOpenProjectReference.find_by(jira_entity_id: jira_user2.id)
      expect(ref2.uses_existing).to be false
    end

    context "when a user already exists at the Jira-key address but has no JiraUser reference" do
      let!(:unreferenced_user) do
        create(:user,
               mail: "shared+JIRAUSER10111@example.com",
               login: "jira_key_existing",
               password: existing_user_password,
               password_confirmation: existing_user_password)
      end

      it "reuses that existing user instead of creating a new one" do
        expect { import_users }.to change(User, :count).by(1)

        ref2 = Import::JiraOpenProjectReference.find_by(jira_entity_id: jira_user2.id)
        expect(ref2.op_entity_id).to eq(unreferenced_user.id.to_s)
      end

      it "marks the reference as uses_existing" do
        import_users

        ref2 = Import::JiraOpenProjectReference.find_by(jira_entity_id: jira_user2.id)
        expect(ref2.uses_existing).to be true
      end
    end

    context "when the Jira-key address is taken by an already-referenced user" do
      let!(:referenced_user) do
        create(:user,
               mail: "shared+JIRAUSER10111@example.com",
               login: "jira_key_referenced",
               password: existing_user_password,
               password_confirmation: existing_user_password)
      end

      before do
        other_jira_user = create(:jira_user, jira_import:,
                                             origin_id: "JIRAUSER99999",
                                             payload: jira_user_payload(key: "JIRAUSER99999", name: "other",
                                                                        display_name: "Other", email: "other@example.com",
                                                                        groups: []))
        create(:jira_open_project_reference,
               jira_import:,
               jira_entity_id: other_jira_user.id,
               jira_entity_class: Import::JiraUser.to_s,
               op_entity_id: referenced_user.id,
               op_entity_class: referenced_user.class.to_s)
      end

      it "falls back with a counter suffix" do
        import_users

        ref2 = Import::JiraOpenProjectReference.find_by(jira_entity_id: jira_user2.id)
        expect(User.find(ref2.op_entity_id).mail).to eq("shared+JIRAUSER10111+1@example.com")
      end
    end
  end
end
