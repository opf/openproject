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
require "rack/test"

RSpec.describe "API v3 Group resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  subject(:response) { last_response }

  shared_let(:project) { create(:project) }
  shared_let(:admin) { create(:admin) }

  let(:group) do
    create(:group, member_with_roles: { project => role }, members:)
  end
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { %i[view_members manage_members] }
  let(:members) do
    create_list(:user, 2)
  end

  current_user do
    create(:user,
           member_with_roles: { project => role })
  end

  describe "GET api/v3/groups/:id" do
    let(:get_path) { api_v3_paths.group group.id }

    before do
      get get_path
    end

    context "having the necessary permission" do
      it "responds with 200 OK" do
        expect(subject.status)
          .to eq(200)
      end

      it "responds with the correct group resource including the members" do
        expect(subject.body)
          .to be_json_eql("Group".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql(group.name.to_json)
          .at_path("name")

        expect(JSON::parse(subject.body).dig("_links", "members").pluck("href"))
          .to match_array(members.map { |m| api_v3_paths.user(m.id) })
      end
    end

    context "when the group is a regular group" do
      it "includes organizationalUnit as false and no parent link" do
        expect(subject.body)
          .to be_json_eql(false.to_json)
          .at_path("organizationalUnit")

        expect(subject.body)
          .not_to have_json_path("_links/parent")
      end
    end

    context "when the group is a department with a parent" do
      let(:parent_department) { create(:department) }
      let(:group) do
        create(:department, parent_id: parent_department.id, member_with_roles: { project => role })
      end
      let(:members) { [] }

      it "includes organizationalUnit as true and the parent link" do
        expect(subject.body)
          .to be_json_eql(true.to_json)
          .at_path("organizationalUnit")

        expect(subject.body)
          .to be_json_eql(api_v3_paths.group(parent_department.id).to_json)
          .at_path("_links/parent/href")
      end
    end

    context "requesting nonexistent group" do
      let(:get_path) { api_v3_paths.group 9999 }

      it_behaves_like "not found"
    end

    context "not having the necessary permission to see any group" do
      let(:permissions) { [] }

      it_behaves_like "unauthorized access"
    end

    context "not having the necessary permission to see the specific group" do
      let(:permissions) { %i[view_members] }
      let(:group) { create(:group) }

      it_behaves_like "not found"
    end
  end

  describe "POST api/v3/groups" do
    let(:path) { api_v3_paths.groups }
    let(:body) do
      {
        name: "The new group",
        members: [
          {
            href: api_v3_paths.user(members.first.id)
          },
          {
            href: api_v3_paths.user(members.last.id)
          }
        ]
      }.to_json
    end

    subject(:response) { post path, body }

    context "when the user is allowed" do
      current_user { admin }

      context "and the input is valid" do
        it "responds with 201" do
          expect(response).to have_http_status(:created)
        end

        it "creates the group and sets the members" do
          subject
          group = Group.find_by(name: "The new group")
          expect(group)
            .to be_present

          expect(group.users)
            .to match_array members
        end

        it "returns the newly created group" do
          expect(response.body)
            .to be_json_eql("Group".to_json)
            .at_path("_type")

          expect(response.body)
            .to be_json_eql("The new group".to_json)
            .at_path("name")
        end
      end

      context "when creating a department" do
        let(:body) do
          {
            name: "New department",
            organizationalUnit: true
          }.to_json
        end

        it "responds with 201 and sets organizationalUnit" do
          expect(response).to have_http_status(:created)

          expect(response.body)
            .to be_json_eql(true.to_json)
            .at_path("organizationalUnit")
        end

        it "persists the organizational_unit flag" do
          response
          group = Group.find_by(name: "New department")
          expect(group.organizational_unit?).to be true
        end
      end

      context "when the user is allowed and the input is invalid" do
        current_user { admin }

        let(:body) do
          {
            name: ""
          }.to_json
        end

        it "responds with 422 and explains the error" do
          expect(response).to have_http_status(:unprocessable_entity)

          expect(response.body)
            .to be_json_eql("Name can't be blank.".to_json)
            .at_path("message")
        end
      end

      describe "custom fields" do
        context "with a required custom field" do
          let!(:required_custom_field) do
            create(:group_custom_field, :string,
                   name: "Department",
                   is_required: true)
          end

          context "when no custom field value is provided" do
            let(:body) { { name: "The new group with CF" }.to_json }

            it "responds with 422 and explains the custom field error" do
              expect(response).to have_http_status(:unprocessable_entity)

              expect(response.body)
                .to be_json_eql("Department can't be blank.".to_json)
                .at_path("message")
            end
          end

          context "when the custom field value is provided but empty" do
            let(:body) do
              {
                name: "The new group with CF",
                "customField#{required_custom_field.id}" => ""
              }.to_json
            end

            it "responds with 422 and explains the custom field error" do
              expect(response).to have_http_status(:unprocessable_entity)

              expect(response.body)
                .to be_json_eql("Department can't be blank.".to_json)
                .at_path("message")
            end
          end

          context "when the custom field value is provided and valid" do
            let(:body) do
              {
                name: "The new group with CF",
                "customField#{required_custom_field.id}" => "Engineering"
              }.to_json
            end

            it "responds with 201" do
              expect(response).to have_http_status(:created)
            end

            it "returns the newly created group" do
              expect(response.body)
                .to be_json_eql("Group".to_json)
                .at_path("_type")

              expect(response.body)
                .to be_json_eql("The new group with CF".to_json)
                .at_path("name")
            end
          end
        end
      end
    end

    context "not having the necessary permission" do
      before { response }

      it_behaves_like "unauthorized access"
    end
  end

  describe "PATCH api/v3/groups/:id" do
    let(:path) { api_v3_paths.group(group.id) }
    let(:another_role) { create(:project_role) }
    let(:another_user) do
      create(:user,
             member_with_roles: { project => another_role },
             notification_settings: [
               build(:notification_setting,
                     membership_added: true,
                     membership_updated: true)
             ])
    end
    let(:body) do
      {
        _links: {
          members: [
            {
              href: api_v3_paths.user(members.last.id)
            },
            {
              href: api_v3_paths.user(another_user.id)
            }
          ]
        }
      }.to_json
    end
    let(:group_updated_at) { group.reload.updated_at }
    let(:other_project) { create(:project) }
    let!(:membership) do
      create(:member,
             principal: group,
             project: other_project,
             roles: [create(:project_role)])
    end

    before do
      # Setup the memberships the group has
      Groups::CreateInheritedRolesService
        .new(group, current_user: admin)
        .call(user_ids: members.map(&:id))

      another_user
      group_updated_at

      perform_enqueued_jobs do
        patch path, body
      end
    end

    context "when the user is allowed and the input is valid" do
      current_user { admin }

      it "responds with 200" do
        expect(response).to have_http_status(:ok)
      end

      it "updates the group" do
        group.reload

        expect(group.users)
          .to contain_exactly(members.last, another_user)

        # Altering only the members still updates the group's timestamp
        expect(group.updated_at > group_updated_at)
          .to be_truthy
      end

      it "returns the updated group" do
        expect(response.body)
          .to be_json_eql("Group".to_json)
          .at_path("_type")

        expect(response.body)
          .to be_json_eql([{ href: api_v3_paths.user(members.last.id), title: members.last.name },
                           { href: api_v3_paths.user(another_user.id), title: another_user.name }].to_json)
          .at_path("_links/members")

        # unchanged
        expect(response.body)
          .to be_json_eql(group.name.to_json)
          .at_path("name")

        # includes the memberships the group has applied to the added user
        expect(other_project.reload.users)
          .to contain_exactly(members.last, another_user)
      end

      it "sends mails notifying of the added and updated project memberships to the added user" do
        expect(ActionMailer::Base.deliveries.size)
          .to eq 2

        expect(ActionMailer::Base.deliveries.map(&:to).flatten.uniq)
          .to match_array another_user.mail

        expect(ActionMailer::Base.deliveries.map(&:subject).flatten)
          .to contain_exactly(I18n.t(:"mail_member_updated_project.subject", project: project.name),
                              I18n.t(:"mail_member_added_project.subject", project: other_project.name))
      end
    end

    context "if attempting to set an empty name" do
      current_user { admin }

      let(:body) do
        {
          _links: {
            members: [
              {
                href: api_v3_paths.user(members.last.id)
              },
              {
                href: api_v3_paths.user(another_user.id)
              }
            ]
          },
          name: ""
        }.to_json
      end

      it "returns 422" do
        expect(response)
          .to have_http_status(422)

        expect(response.body)
          .to be_json_eql("Name can't be blank.".to_json)
          .at_path("message")
      end

      it "does not alter the group" do
        group.reload

        expect(group.users)
          .to match_array members

        expect(group.updated_at)
          .to eql group_updated_at
      end
    end

    describe "custom fields" do
      current_user { admin }

      context "with a required custom field" do
        let!(:required_custom_field) do
          create(:group_custom_field, :string,
                 name: "Department",
                 is_required: true)
        end

        context "when no custom field value is provided" do
          it "responds with 200" do
            expect(response).to have_http_status(:ok)
          end

          it "keeps the custom field value empty" do
            response
            expect(group.reload.typed_custom_value_for(required_custom_field))
              .to be_nil
          end
        end

        context "when the custom field is provided but empty" do
          let(:body) do
            {
              _links: {
                members: [
                  {
                    href: api_v3_paths.user(members.last.id)
                  },
                  {
                    href: api_v3_paths.user(another_user.id)
                  }
                ]
              },
              "customField#{required_custom_field.id}" => ""
            }.to_json
          end

          it "responds with 422 and explains the custom field error" do
            expect(response).to have_http_status(:unprocessable_entity)

            expect(response.body)
              .to be_json_eql("Department can't be blank.".to_json)
              .at_path("message")
          end

          it "does not alter the group" do
            group.reload

            expect(group.users)
              .to match_array members

            expect(group.updated_at)
              .to eql group_updated_at
          end
        end

        context "when the custom field value is being cleared" do
          let(:group_updated_at_with_cf) { group.reload.updated_at }
          let(:body) do
            {
              _links: {
                members: [
                  {
                    href: api_v3_paths.user(members.last.id)
                  },
                  {
                    href: api_v3_paths.user(another_user.id)
                  }
                ]
              },
              "customField#{required_custom_field.id}" => ""
            }.to_json
          end

          before do
            # Set an initial value for the custom field
            group.custom_field_values = { required_custom_field.id => "Initial Department" }
            group.save!
            group_updated_at_with_cf
          end

          it "responds with 422 and explains the custom field error" do
            expect(response).to have_http_status(:unprocessable_entity)

            expect(response.body)
              .to be_json_eql("Department can't be blank.".to_json)
              .at_path("message")
          end

          it "does not alter the group" do
            group.reload

            expect(group.users)
              .to match_array members

            expect(group.updated_at)
              .to eql group_updated_at_with_cf

            # Custom field value should remain unchanged
            expect(group.typed_custom_value_for(required_custom_field))
              .to eq("Initial Department")
          end
        end

        context "when the custom field value is provided and valid" do
          let(:body) do
            {
              _links: {
                members: [
                  {
                    href: api_v3_paths.user(members.last.id)
                  },
                  {
                    href: api_v3_paths.user(another_user.id)
                  }
                ]
              },
              name: "Updated group with valid CF",
              "customField#{required_custom_field.id}" => "Engineering"
            }.to_json
          end

          it "responds with 200" do
            expect(response).to have_http_status(:ok)
          end

          it "updates the group with the custom field value" do
            response
            expect(group.reload.typed_custom_value_for(required_custom_field))
              .to eq("Engineering")
          end
        end
      end
    end

    context "when not being an admin" do
      let(:permissions) { [:manage_members] }

      it_behaves_like "unauthorized access"
    end

    context "when lacking the view permissions" do
      let(:permissions) { [] }

      it_behaves_like "unauthorized access"
    end
  end

  describe "PATCH api/v3/groups/:id (department user validation)" do
    current_user { admin }

    context "when adding a user who is already in another department" do
      let(:user_to_add) { create(:user) }
      let!(:other_department) { create(:department, members: [user_to_add]) }
      let(:department) { create(:department) }

      let(:body) do
        {
          _links: {
            members: [
              { href: api_v3_paths.user(user_to_add.id) }
            ]
          }
        }.to_json
      end

      before do
        perform_enqueued_jobs do
          patch api_v3_paths.group(department.id), body
        end
      end

      it "responds with 422" do
        expect(last_response).to have_http_status(:unprocessable_entity)
      end

      it "includes the error message with user and department ids" do
        parsed_message = JSON.parse(last_response.body)["message"]
        expect(parsed_message).to include(user_to_add.id.to_s)
        expect(parsed_message).to include(other_department.id.to_s)
      end

      it "does not add the user to the department" do
        expect(department.reload.users).not_to include(user_to_add)
      end
    end

    context "when adding multiple users who are each already in other departments" do
      let(:user_a) { create(:user) }
      let(:user_b) { create(:user) }
      let!(:department_a) { create(:department, members: [user_a]) }
      let!(:department_b) { create(:department, members: [user_b]) }
      let(:department) { create(:department) }

      let(:body) do
        {
          _links: {
            members: [
              { href: api_v3_paths.user(user_a.id) },
              { href: api_v3_paths.user(user_b.id) }
            ]
          }
        }.to_json
      end

      before do
        perform_enqueued_jobs do
          patch api_v3_paths.group(department.id), body
        end
      end

      it "responds with 422" do
        expect(last_response).to have_http_status(:unprocessable_entity)
      end

      it "returns multiple errors" do
        parsed = JSON.parse(last_response.body)
        errors = parsed.dig("_embedded", "errors")

        expect(errors.length).to eq(2)

        error_messages = errors.pluck("message")
        expect(error_messages).to contain_exactly(
          a_string_including(user_a.id.to_s).and(a_string_including(department_a.id.to_s)),
          a_string_including(user_b.id.to_s).and(a_string_including(department_b.id.to_s))
        )
      end
    end
  end

  describe "PATCH api/v3/groups/:id (department properties)" do
    current_user { admin }

    context "when attempting to change organizational_unit" do
      let(:department) { create(:department) }

      let(:body) do
        { organizationalUnit: false }.to_json
      end

      before do
        perform_enqueued_jobs do
          patch api_v3_paths.group(department.id), body
        end
      end

      it "does not change organizational_unit" do
        expect(department.reload.organizational_unit?).to be true
      end

      it "responds with 422 but ignores the change" do
        expect(last_response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when setting a parent on a department" do
      let(:parent_department) { create(:department) }
      let(:department) { create(:department) }

      let(:body) do
        {
          _links: {
            parent: { href: api_v3_paths.group(parent_department.id) }
          }
        }.to_json
      end

      before do
        perform_enqueued_jobs do
          patch api_v3_paths.group(department.id), body
        end
      end

      it "responds with 200" do
        expect(last_response).to have_http_status(:ok)
      end

      it "sets the parent" do
        expect(last_response.body)
          .to be_json_eql(api_v3_paths.group(parent_department.id).to_json)
          .at_path("_links/parent/href")

        expect(department.reload.parent_id).to eq(parent_department.id)
      end
    end
  end

  describe "DELETE /api/v3/groups/:id" do
    let(:path) { api_v3_paths.group(group.id) }
    let(:other_project) { create(:project) }
    let!(:membership) do
      create(:member,
             principal: group,
             project: other_project,
             roles: [create(:project_role)])
    end
    let(:another_role) { create(:project_role) }

    before do
      # Setup the memberships in the group has
      Groups::CreateInheritedRolesService
        .new(group, current_user: admin)
        .call(user_ids: members.map(&:id))

      # Have one user have a role independent of the group
      Member
        .find_by(principal: members.first, project: other_project)
        .roles << another_role

      login_as current_user

      perform_enqueued_jobs do
        delete path
      end
    end

    context "with required permissions" do
      current_user { admin }

      it "responds with 202" do
        expect(subject.status).to eq 202
      end

      it "deletes the group" do
        expect(Group)
          .not_to exist(group.id)
      end

      it "deletes the memberships of the members but keeps the ones a user had independently of the group" do
        expect(other_project.users)
          .to contain_exactly(members.first)

        expect(Member.find_by(principal: members.first).roles)
          .to contain_exactly(another_role)
      end

      context "for a non-existent group" do
        let(:path) { api_v3_paths.group 11111337 }

        it_behaves_like "not found"
      end
    end

    context "without permission to delete groups" do
      it_behaves_like "unauthorized access"

      it "does not delete the member" do
        expect(Group)
          .to exist(group.id)
      end
    end
  end

  describe "GET api/v3/groups" do
    let(:get_path) { api_v3_paths.groups }
    let(:other_group) do
      create(:group)
    end

    before do
      group
      other_group

      get get_path
    end

    context "when visible" do
      let(:current_user) { create(:user, global_permissions: %i[view_all_principals]) }

      it_behaves_like "API V3 collection response", 2, 2, "Group" do
        let(:elements) { [other_group, group] }
      end
    end

    context "when only mine is visible" do
      it_behaves_like "API V3 collection response", 1, 1, "Group" do
        let(:elements) { [group] }
      end
    end

    context "when signaling" do
      let(:current_user) { admin }
      let(:get_path) { api_v3_paths.path_for :groups, select: "total,count,elements/*" }

      let(:expected) do
        {
          total: 2,
          count: 2,
          _embedded: {
            elements: [
              {
                _type: "Group",
                id: other_group.id,
                name: other_group.name,
                email: "",
                _links: {
                  self: {
                    href: api_v3_paths.group(other_group.id),
                    title: other_group.name
                  }
                }
              },
              {
                _type: "Group",
                id: group.id,
                name: group.name,
                email: "",
                _links: {
                  self: {
                    href: api_v3_paths.group(group.id),
                    title: group.name
                  }
                }
              }
            ]
          }
        }
      end

      it "is the reduced set of properties of the embedded elements" do
        expect(response.body)
          .to be_json_eql(expected.to_json)
      end
    end

    context "when not having the necessary permission" do
      let(:permissions) { [] }

      it_behaves_like "unauthorized access"
    end
  end
end
