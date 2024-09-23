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

RSpec.describe "API v3 memberships resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project) }
  shared_let(:current_user) do
    create(:user)
  end
  shared_let(:admin) do
    create(:admin)
  end
  shared_let(:other_role) { create(:project_role) }
  shared_let(:global_role) { create(:global_role) }
  let(:own_member) do
    create(:member,
           roles: create_list(:project_role, 1, permissions:),
           project:,
           user: current_user)
  end
  let(:permissions) { %i[view_members manage_members] }
  let(:other_user) { create(:user) }
  let(:other_member) do
    create(:member,
           roles: [other_role],
           principal: other_user,
           project:)
  end
  let(:invisible_member) do
    create(:member,
           roles: create_list(:project_role, 1))
  end
  let(:global_member) do
    create(:global_member,
           roles: [global_role])
  end

  let(:work_package) { create(:work_package, project:) }
  let(:work_package_member) do
    create(:member,
           user: current_user,
           project:,
           entity: work_package,
           roles: create_list(:work_package_role, 1))
  end

  subject(:response) { last_response }

  shared_examples_for "sends mails" do
    let(:expected_receivers) { defined?(receivers) ? receivers : [principal] }

    it "sends a mail to the principal of the member" do
      expect(ActionMailer::Base.deliveries.size)
        .to eql expected_receivers.length

      expect(ActionMailer::Base.deliveries.map(&:to).flatten)
        .to match_array expected_receivers.map(&:mail)

      if defined?(custom_message)
        expect(ActionMailer::Base.deliveries.map { |mail| mail.body.encoded })
          .to all include(OpenProject::TextFormatting::Renderer.format_text(custom_message))
      end
    end
  end

  describe "GET api/v3/memberships" do
    let(:members) { [own_member, other_member, invisible_member, global_member, work_package_member] }
    let(:filters) { nil }
    let(:path) { api_v3_paths.path_for(:memberships, filters:, sort_by: [%i(id asc)]) }

    before do
      members

      login_as(current_user)

      get path
    end

    context "without params" do
      it "responds 200 OK" do
        expect(subject.status).to eq(200)
      end

      it "returns a collection of memberships containing only the visible ones" do
        expect(subject.body)
          .to be_json_eql("Collection".to_json)
          .at_path("_type")

        # the one membership stems from the membership the user has himself
        expect(subject.body)
          .to be_json_eql("2")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql(own_member.id.to_json)
          .at_path("_embedded/elements/0/id")

        expect(subject.body)
          .to be_json_eql(other_member.id.to_json)
          .at_path("_embedded/elements/1/id")
      end
    end

    context "as an admin" do
      let(:current_user) { admin }

      it "returns a collection of memberships containing only the visible ones", :aggregate_failures do
        expect(subject.status).to eq(200)

        expect(subject.body)
          .to be_json_eql("Collection".to_json)
          .at_path("_type")

        # the one membership stems from the membership the user has himself
        expect(subject.body)
          .to be_json_eql("4")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql(own_member.id.to_json)
          .at_path("_embedded/elements/0/id")

        expect(subject.body)
          .to be_json_eql(other_member.id.to_json)
          .at_path("_embedded/elements/1/id")

        expect(subject.body)
          .to be_json_eql(invisible_member.id.to_json)
          .at_path("_embedded/elements/2/id")

        expect(subject.body)
          .to be_json_eql(global_member.id.to_json)
          .at_path("_embedded/elements/3/id")
      end
    end

    context "with pageSize, offset and sortBy" do
      let(:path) { "#{api_v3_paths.path_for(:memberships, sort_by: [%i(id asc)])}&pageSize=1&offset=2" }

      it "returns a slice of the visible memberships" do
        expect(subject.body)
          .to be_json_eql("Collection".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql("2")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql("1")
          .at_path("count")

        expect(subject.body)
          .to be_json_eql(other_member.id.to_json)
          .at_path("_embedded/elements/0/id")
      end
    end

    context "with a group" do
      let(:group) { create(:group) }
      let(:group_member) do
        create(:member,
               roles: create_list(:project_role, 1),
               project:,
               principal: group)
      end
      let(:members) { [own_member, group_member] }

      it "returns that group membership together with the rest of them" do
        expect(subject.body)
          .to be_json_eql("Collection".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql("2")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql(own_member.id.to_json)
          .at_path("_embedded/elements/0/id")

        expect(subject.body)
          .to be_json_eql(group_member.id.to_json)
          .at_path("_embedded/elements/1/id")
      end
    end

    context "with a placeholder_user" do
      let(:placeholder_user) do
        create(:placeholder_user)
      end
      let(:placeholder_member) do
        create(:member,
               roles: create_list(:project_role, 1),
               project:,
               principal: placeholder_user)
      end
      let(:members) { [own_member, placeholder_member] }

      it "returns that placeholder user membership together with the rest of them" do
        expect(subject.body)
          .to be_json_eql("Collection".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql("2")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql(own_member.id.to_json)
          .at_path("_embedded/elements/0/id")

        expect(subject.body)
          .to be_json_eql(placeholder_member.id.to_json)
          .at_path("_embedded/elements/1/id")
      end
    end

    context "when filtering by user name" do
      let(:filters) do
        [{ "any_name_attribute" => {
          "operator" => "~",
          "values" => [other_member.principal.login]
        } }]
      end

      it "contains only the filtered member in the response" do
        expect(subject.body)
          .to be_json_eql("1")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql(other_member.id.to_json)
          .at_path("_embedded/elements/0/id")
      end
    end

    context "when filtering by project" do
      let(:members) { [own_member, other_member, invisible_member, own_other_member] }

      let(:own_other_member) do
        create(:member,
               roles: create_list(:project_role, 1, permissions:),
               project: other_project,
               user: current_user)
      end

      let(:other_project) { create(:project) }

      let(:filters) do
        [{ "project" => {
          "operator" => "=",
          "values" => [other_project.id]
        } }]
      end

      it "contains only the filtered memberships in the response" do
        expect(subject.body)
          .to be_json_eql("1")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql(own_other_member.id.to_json)
          .at_path("_embedded/elements/0/id")
      end
    end

    context "when filtering by principal" do
      let(:group) { create(:group) }
      let(:group_member) do
        create(:member,
               roles: create_list(:project_role, 1),
               principal: group,
               project:)
      end
      let(:members) { [own_member, other_member, group_member, invisible_member] }

      let(:filters) do
        [{ "principal" => {
          "operator" => "=",
          "values" => [group.id.to_s, current_user.id.to_s]
        } }]
      end

      it "contains only the filtered members in the response" do
        expect(subject.body)
          .to be_json_eql("2")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql(own_member.id.to_json)
          .at_path("_embedded/elements/0/id")

        expect(subject.body)
          .to be_json_eql(group_member.id.to_json)
          .at_path("_embedded/elements/1/id")
      end

      context "when principal is a group without any memberships" do
        let(:members) { [own_member, other_member, invisible_member] }
        let(:filters) do
          [{ "principal" => {
            "operator" => "=",
            "values" => [group.id.to_s]
          } }]
        end

        it "returns empty members" do
          expect(subject.status).to eq(200)

          expect(subject.body)
          .to be_json_eql([])
          .at_path("_embedded/elements")
        end
      end
    end

    context "with the outdated created_on sort by (renamed to created_at)" do
      let(:path) { "#{api_v3_paths.path_for(:memberships, sort_by: [%i(created_on desc)])}&pageSize=1&offset=2" }

      it "is still supported and returns a slice of the visible memberships" do
        expect(subject.body)
          .to be_json_eql("Collection".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql("2")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql("1")
          .at_path("count")

        expect(subject.body)
          .to be_json_eql(own_member.id.to_json)
          .at_path("_embedded/elements/0/id")
      end
    end

    context "invalid filter" do
      let(:members) { [own_member] }

      let(:filters) do
        [{ "bogus" => {
          "operator" => "=",
          "values" => ["1"]
        } }]
      end

      it "returns an error" do
        expect(subject.status).to eq(400)

        expect(subject.body)
          .to be_json_eql("urn:openproject-org:api:v3:errors:InvalidQuery".to_json)
          .at_path("errorIdentifier")
      end
    end

    context "without permissions" do
      let(:permissions) { [] }

      it "is empty" do
        expect(subject.body)
          .to be_json_eql("0")
          .at_path("total")
      end
    end
  end

  describe "POST api/v3/memberships" do
    let(:path) { api_v3_paths.memberships }
    let(:principal) { other_user }
    let(:principal_path) { api_v3_paths.user(principal.id) }
    let(:custom_message) { "Wish you where **here**." }
    let(:body) do
      {
        _links: {
          project: {
            href: api_v3_paths.project(project.id)
          },
          principal: {
            href: principal_path
          },
          roles: [
            {
              href: api_v3_paths.role(other_role.id)
            }
          ]
        },
        _meta: {
          notificationMessage: {
            raw: custom_message
          }
        }
      }.to_json
    end

    before do
      own_member
      login_as current_user

      perform_enqueued_jobs do
        post path, body
      end
    end

    shared_examples_for "successful member creation" do
      let(:role) { defined?(expected_role) ? expected_role : other_role }

      it "responds with 201" do
        expect(last_response).to have_http_status(:created)
      end

      it "creates the member" do
        expect(Member.find_by(principal:, project:))
          .to be_present
      end

      it "returns the newly created member" do
        expect(last_response.body)
          .to be_json_eql("Membership".to_json)
          .at_path("_type")

        if project
          expect(last_response.body)
            .to be_json_eql(api_v3_paths.project(project.id).to_json)
            .at_path("_links/project/href")
        end

        expect(last_response.body)
          .to be_json_eql(principal_path.to_json)
          .at_path("_links/principal/href")

        expect(last_response.body)
          .to have_json_size(1)
          .at_path("_links/roles")

        expect(last_response.body)
          .to be_json_eql(api_v3_paths.role(role.id).to_json)
          .at_path("_links/roles/0/href")
      end
    end

    context "for a user" do
      it_behaves_like "successful member creation"
      it_behaves_like "sends mails"

      context "when deactivating notification sending" do
        let(:body) do
          {
            _links: {
              project: {
                href: api_v3_paths.project(project.id)
              },
              principal: {
                href: principal_path
              },
              roles: [
                {
                  href: api_v3_paths.role(other_role.id)
                }
              ]
            },
            _meta: {
              sendNotifications: false
            }
          }.to_json
        end

        it_behaves_like "successful member creation"

        it "sends no mail to the principal of the member" do
          expect(ActionMailer::Base.deliveries)
            .to be_empty
        end
      end
    end

    context "for a group" do
      let(:group) do
        create(:group, members: users)
      end
      let(:principal) { group }
      let(:users) { create_list(:user, 2) }
      let(:principal_path) { api_v3_paths.group(group.id) }
      let(:body) do
        {
          _links: {
            project: {
              href: api_v3_paths.project(project.id)
            },
            principal: {
              href: principal_path
            },
            roles: [
              {
                href: api_v3_paths.role(other_role.id)
              }
            ]
          },
          _meta: {
            notificationMessage: {
              raw: custom_message
            }
          }
        }.to_json
      end

      it_behaves_like "successful member creation"
      it_behaves_like "sends mails" do
        let(:receivers) { users }
      end

      it "creates the memberships for the group members" do
        users.each do |user|
          expect(Member.find_by(user_id: user.id, project:))
            .to be_present
        end
      end

      context "when deactivating notification sending" do
        let(:body) do
          {
            _links: {
              project: {
                href: api_v3_paths.project(project.id)
              },
              principal: {
                href: principal_path
              },
              roles: [
                {
                  href: api_v3_paths.role(other_role.id)
                }
              ]
            },
            _meta: {
              sendNotifications: false
            }
          }.to_json
        end

        it_behaves_like "successful member creation"

        it "sends no mail to the principal of the member" do
          expect(ActionMailer::Base.deliveries)
            .to be_empty
        end
      end

      context "when creating global role permission as admin" do
        let(:current_user) { admin }
        let(:project) { nil }
        let(:expected_role) { global_role }
        let(:body) do
          {
            _links: {
              principal: {
                href: principal_path
              },
              roles: [
                {
                  href: api_v3_paths.role(global_role.id)
                }
              ]
            },
            _meta: {
              notificationMessage: {
                raw: custom_message
              }
            }
          }.to_json
        end

        it_behaves_like "successful member creation"
      end
    end

    context "for a placeholder user" do
      let(:placeholder_user) { create(:placeholder_user) }
      let(:principal) { placeholder_user }
      let(:principal_path) { api_v3_paths.placeholder_user(placeholder_user.id) }
      let(:body) do
        {
          _links: {
            project: {
              href: api_v3_paths.project(project.id)
            },
            principal: {
              href: principal_path
            },
            roles: [
              {
                href: api_v3_paths.role(other_role.id)
              }
            ]
          },
          _meta: {
            notificationMessage: {
              raw: custom_message
            }
          }
        }.to_json
      end

      it_behaves_like "successful member creation"

      it_behaves_like "sends mails" do
        let(:receivers) { [] }
      end
    end

    context "for a global membership" do
      let(:expected_role) { global_role }
      let(:body) do
        {
          _links: {
            project: {
              href: nil
            },
            principal: {
              href: principal_path
            },
            roles: [
              {
                href: api_v3_paths.role(global_role.id)
              }
            ]
          },
          _meta: {
            notificationMessage: {
              raw: custom_message
            }
          }
        }.to_json
      end
      let(:project) { nil }

      context "as an admin" do
        let(:current_user) { admin }

        it_behaves_like "successful member creation"
        it_behaves_like "sends mails"
      end

      context "as a non admin" do
        it "responds with 422 and explains the error" do
          expect(last_response).to have_http_status(:unprocessable_entity)

          expect(last_response.body)
            .to be_json_eql("Project can't be blank.".to_json)
            .at_path("message")
        end
      end
    end

    context "if providing an already taken user" do
      let(:body) do
        {
          _links: {
            project: {
              href: api_v3_paths.project(project.id)
            },
            principal: {
              # invalid as the current_user is already member
              href: api_v3_paths.user(current_user.id)
            },
            roles: [
              {
                href: api_v3_paths.role(other_role.id)
              }
            ]
          }
        }.to_json
      end

      it "responds with 422 and explains the error" do
        expect(last_response).to have_http_status(:unprocessable_entity)

        expect(last_response.body)
          .to be_json_eql("User has already been taken.".to_json)
          .at_path("message")
      end
    end

    context "if providing erroneous hrefs" do
      let(:body) do
        {
          _links: {
            project: {
              href: api_v3_paths.project(project.id)
            },
            principal: {
              # role path instead of user
              href: api_v3_paths.role(other_user.id)
            },
            roles: [
              {
                href: api_v3_paths.role(other_role.id)
              }
            ]
          }
        }.to_json
      end

      it "responds with 422 and explains the error" do
        expect(last_response).to have_http_status(:unprocessable_entity)

        error_message = "For property 'user' a link like '/api/v3/groups/:id' or " +
                        "'/api/v3/users/:id' or '/api/v3/placeholder_users/:id' is expected, " +
                        "but got '#{api_v3_paths.role(other_user.id)}'."

        expect(last_response.body)
          .to be_json_eql(error_message.to_json)
          .at_path("message")
      end
    end

    context "if providing no roles" do
      let(:body) do
        {
          _links: {
            project: {
              href: api_v3_paths.project(project.id)
            },
            principal: {
              href: principal_path
            },
            roles: []
          }
        }.to_json
      end

      it "responds with 422 and explains the error" do
        expect(last_response).to have_http_status(:unprocessable_entity)

        expect(last_response.body)
          .to be_json_eql("Roles need to be assigned.".to_json)
          .at_path("message")
      end
    end

    context "if lacking the manage permissions" do
      let(:permissions) { [:view_members] }

      it_behaves_like "unauthorized access"
    end
  end

  describe "GET /api/v3/memberships/:id" do
    let(:path) { api_v3_paths.membership(other_member.id) }

    let(:members) { [own_member, other_member] }

    before do
      members

      login_as(current_user)

      get path
    end

    it "returns 200 OK" do
      expect(subject.status)
        .to be(200)
    end

    it "returns the member" do
      expect(subject.body)
        .to be_json_eql("Membership".to_json)
        .at_path("_type")

      expect(subject.body)
        .to be_json_eql(other_member.id.to_json)
        .at_path("id")
    end

    context "if querying an invisible member" do
      let(:path) { api_v3_paths.membership(invisible_member.id) }

      let(:members) { [own_member, invisible_member] }

      it "returns 404 NOT FOUND" do
        expect(subject.status)
          .to be(404)
      end
    end

    context "without the necessary permissions" do
      let(:permissions) { [] }

      it "returns 404 NOT FOUND" do
        expect(subject.status)
          .to be(404)
      end
    end
  end

  describe "PATCH api/v3/memberships/:id" do
    let(:path) { api_v3_paths.membership(other_member.id) }
    let(:another_role) { create(:project_role) }
    let(:custom_message) { "Wish you where **here**." }
    let(:body) do
      {
        _links: {
          roles: [
            {
              href: api_v3_paths.role(another_role.id)
            }
          ]
        },
        _meta: {
          notificationMessage: {
            raw: custom_message
          }
        }
      }.to_json
    end

    let(:members) { [own_member, other_member] }
    let!(:other_member_updated_at) { other_member.updated_at }

    before do
      members

      login_as current_user

      perform_enqueued_jobs do
        patch path, body
      end
    end

    context "for a user" do
      it "responds with 200" do
        expect(last_response).to have_http_status(:ok)
      end

      it "updates the member" do
        other_member.reload

        expect(other_member.roles)
          .to contain_exactly(another_role)

        # Assigning a new role also updates the member
        expect(other_member.updated_at > other_member_updated_at)
          .to be_truthy
      end

      it "returns the updated membership" do
        expect(last_response.body)
          .to be_json_eql("Membership".to_json)
          .at_path("_type")

        expect(last_response.body)
          .to be_json_eql([{ href: api_v3_paths.role(another_role.id), title: another_role.name }].to_json)
          .at_path("_links/roles")

        # unchanged
        expect(last_response.body)
          .to be_json_eql(project.name.to_json)
          .at_path("_links/project/title")

        expect(last_response.body)
          .to be_json_eql(other_user.name.to_json)
          .at_path("_links/principal/title")
      end

      it_behaves_like "sends mails" do
        let(:receivers) { [other_member.principal] }
      end

      context "when deactivating notification sending" do
        let(:body) do
          {
            _links: {
              roles: [
                {
                  href: api_v3_paths.role(another_role.id)
                }
              ]
            },
            _meta: {
              sendNotifications: false
            }
          }.to_json
        end

        it "sends no mail to the principal of the member" do
          expect(ActionMailer::Base.deliveries)
            .to be_empty
        end
      end
    end

    context "with a group" do
      # first user has no direct roles
      # second user has direct role `another_role`
      # both users belong to a group which has `other_role`, so this role is inherited by users
      # when updating `group` role from `other_role` to `another_role`
      # expecting to have first user role changed from `other_role` to `another_role`
      # and second user role extended from `[other_role]` to `[other_role, another_role]` because has direct role
      let(:group) do
        create(:group, member_with_roles: { project => other_role }, members: users)
      end
      let(:principal) { group }
      let(:users) { create_list(:user, 2) }
      let(:other_member) do
        Member.find_by(principal: group).tap do
          # Behaves as if the user had that role before the role's membership was created.
          # Because the user had the role independent of the group, it is not to be removed.
          user_member = Member.find_by(principal: users.first)

          MemberRole
            .where(member_id: user_member.id)
            .update_all(inherited_from: nil)

          # The user also had the newly assigned role before. The membership should therefore remain unchanged.
          user_member.member_roles.create(role_id: another_role.id)

          first_user_member_updated_at
          last_user_member_updated_at
        end
      end
      let(:first_user_member_updated_at) { Member.find_by(principal: users.first).updated_at }
      let(:last_user_member_updated_at) { Member.find_by(principal: users.last).updated_at }

      it "responds with 200" do
        expect(last_response).to have_http_status(:ok)
      end

      it "updates the member and all inherited members but does not update memberships users have already had" do
        expect(other_member.reload.roles)
          .to contain_exactly(another_role)

        expect(other_member.updated_at > other_member_updated_at)
          .to be_truthy

        last_user_member = Member.find_by(principal: users.last)

        expect(last_user_member.roles)
          .to contain_exactly(another_role)

        expect(last_user_member.updated_at > last_user_member_updated_at)
          .to be_truthy

        first_user_member = Member.find_by(principal: users.first)

        expect(first_user_member.roles.uniq)
          .to contain_exactly(other_role, another_role)

        expect(first_user_member.updated_at)
          .to eql first_user_member_updated_at
      end

      it "returns the updated membership" do
        expect(last_response.body)
          .to be_json_eql("Membership".to_json)
          .at_path("_type")

        expect(last_response.body)
          .to be_json_eql([{ href: api_v3_paths.role(another_role.id), title: another_role.name }].to_json)
          .at_path("_links/roles")

        # unchanged
        expect(last_response.body)
          .to be_json_eql(project.name.to_json)
          .at_path("_links/project/title")

        expect(last_response.body)
          .to be_json_eql(group.name.to_json)
          .at_path("_links/principal/title")
      end

      it_behaves_like "sends mails" do
        # Only sends to the second user since the first user's membership is unchanged
        let(:receivers) { [users.last] }
      end

      context "when deactivating notification sending" do
        let(:body) do
          {
            _links: {
              roles: [
                {
                  href: api_v3_paths.role(another_role.id)
                }
              ]
            },
            _meta: {
              sendNotifications: false
            }
          }.to_json
        end

        it "sends no mail to the principal of the member" do
          expect(ActionMailer::Base.deliveries)
            .to be_empty
        end
      end

      context "when updating global role permission as admin" do
        let(:group) do
          create(:group, global_roles: [other_role], members: users)
        end
        let(:current_user) { admin }
        let(:project) { nil }
        let(:other_role) { create(:global_role) }
        let(:another_role) { create(:global_role) }

        it "responds with 200" do
          expect(last_response).to have_http_status(:ok)
        end

        it "updates the member and all inherited members but does not update memberships users have already had" do
          # other member is the group member
          expect(other_member.reload.roles)
            .to contain_exactly(another_role)

          expect(other_member.updated_at > other_member_updated_at)
            .to be_truthy

          last_user_member = Member.find_by(principal: users.last)

          expect(last_user_member.roles)
            .to contain_exactly(another_role)

          expect(last_user_member.updated_at > last_user_member_updated_at)
            .to be_truthy

          first_user_member = Member.find_by(principal: users.first)

          expect(first_user_member.roles.uniq)
            .to contain_exactly(other_role, another_role)

          expect(first_user_member.updated_at)
            .to eql first_user_member_updated_at
        end
      end
    end

    context "if attempting to empty the roles" do
      let(:body) do
        {
          _links: {
            roles: []
          }
        }.to_json
      end

      it "returns 422" do
        expect(last_response.status)
          .to be(422)

        expect(last_response.body)
          .to be_json_eql("Roles need to be assigned.".to_json)
          .at_path("message")
      end
    end

    context "if attempting to assign unassignable roles" do
      let(:anonymous_role) { create(:anonymous_role) }
      let(:body) do
        {
          _links: {
            roles: [
              {
                href: api_v3_paths.role(anonymous_role.id)
              }
            ]
          }
        }.to_json
      end

      it "returns 422" do
        expect(last_response.status)
          .to be(422)

        expect(last_response.body)
          .to be_json_eql("Roles has an unassignable role.".to_json)
          .at_path("message")
      end
    end

    context "when attempting to switch the project" do
      let(:other_project) do
        create(:project).tap do |p|
          create(:member,
                 project: p,
                 roles: create_list(:project_role, 1, permissions: [:manage_members]),
                 user: current_user)
        end
      end

      let(:body) do
        {
          _links: {
            project: {
              href: api_v3_paths.project(other_project.id)

            }
          }
        }.to_json
      end

      it_behaves_like "read-only violation", "project", Member
    end

    context "if attempting to switch the principal" do
      let(:another_user) do
        create(:user)
      end

      let(:body) do
        {
          _links: {
            principal: {
              href: api_v3_paths.user(another_user.id)

            }
          }
        }.to_json
      end

      it_behaves_like "read-only violation", "user", Member
    end

    context "if lacking the manage permissions" do
      let(:permissions) { [:view_members] }

      it_behaves_like "unauthorized access"
    end

    context "if lacking the view permissions" do
      let(:permissions) { [] }

      it_behaves_like "not found"
    end
  end

  describe "DELETE /api/v3/memberships/:id" do
    let(:path) { api_v3_paths.membership(other_member.id) }
    let(:members) { [own_member, other_member] }

    before do
      members
      login_as current_user

      perform_enqueued_jobs do
        delete path
      end
    end

    subject { last_response }

    context "with required permissions" do
      it "responds with HTTP No Content" do
        expect(subject.status).to eq 204
      end

      it "deletes the member" do
        expect(Member).not_to exist(other_member.id)
      end

      context "for a non-existent version" do
        let(:path) { api_v3_paths.membership 1337 }

        it_behaves_like "not found"
      end
    end

    context "with a group" do
      let(:group) do
        create(:group, member_with_roles: { project => other_role }, members: users)
      end
      let(:principal) { group }
      let(:users) do
        create_list(:user, 2,
                    notification_settings: [build(:notification_setting, membership_added: true, membership_updated: true)])
      end
      let(:another_role) { create(:project_role) }
      let(:other_member) do
        Member.find_by(principal: group).tap do
          # Behaves as if the user had a role before the role's membership was created.
          # Because the user had the role independent of the group, it is not to be removed.
          user_member = Member.find_by(principal: users.first)

          # The user also had the newly assigned role before. The membership should therefore remain unchanged.
          user_member.member_roles.create(role_id: another_role.id)

          first_user_member_updated_at
        end
      end
      let(:first_user_member_updated_at) { Member.find_by(principal: users.first).updated_at }

      it "responds with HTTP No Content" do
        expect(subject.status).to eq 204
      end

      it "deletes the member but does not remove the previously assigned role" do
        expect(Member).not_to exist(other_member.id)
        expect(Member.where(principal: users.last)).not_to be_exists

        first_user_member = Member.find_by(principal: users.first)

        expect(first_user_member.roles)
          .to contain_exactly(another_role)

        expect(first_user_member.updated_at > first_user_member_updated_at)
          .to be_truthy
      end

      it_behaves_like "sends mails" do
        # Only sends to the user who's membership only got updated, not removed
        let(:receivers) { [users.first] }
      end
    end

    context "without permission to delete members" do
      let(:permissions) { [:view_members] }

      it_behaves_like "unauthorized access"

      it "does not delete the member" do
        expect(Member).to exist(other_member.id)
      end
    end
  end
end
