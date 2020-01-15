#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe 'API v3 memberhips resource', type: :request, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    FactoryBot.create(:user)
  end
  let(:own_member) do
    FactoryBot.create(:member,
                      roles: [FactoryBot.create(:role, permissions: permissions)],
                      project: project,
                      user: current_user)
  end
  let(:permissions) { %i[view_members manage_members] }
  let(:project) { FactoryBot.create(:project) }
  let(:other_role) { FactoryBot.create(:role) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:other_member) do
    FactoryBot.create(:member,
                      roles: [other_role],
                      principal: other_user,
                      project: project)
  end
  let(:invisible_member) do
    FactoryBot.create(:member,
                      roles: [FactoryBot.create(:role)])
  end

  subject(:response) { last_response }

  describe 'GET api/v3/memberships' do
    let(:members) { [own_member, other_member, invisible_member] }

    before do
      members

      login_as(current_user)

      get path
    end

    let(:filters) { nil }
    let(:path) { api_v3_paths.path_for(:memberships, filters: filters, sort_by: [%i(id asc)]) }

    context 'without params' do
      it 'responds 200 OK' do
        expect(subject.status).to eq(200)
      end

      it 'returns a collection of memberships containing only the visible ones' do
        expect(subject.body)
          .to be_json_eql('Collection'.to_json)
          .at_path('_type')

        # the one membership stems from the membership the user has himself
        expect(subject.body)
          .to be_json_eql('2')
          .at_path('total')

        expect(subject.body)
          .to be_json_eql(own_member.id.to_json)
          .at_path('_embedded/elements/0/id')

        expect(subject.body)
          .to be_json_eql(other_member.id.to_json)
          .at_path('_embedded/elements/1/id')
      end
    end

    context 'with pageSize, offset and sortBy' do
      let(:path) { "#{api_v3_paths.path_for(:memberships, sort_by: [%i(id asc)])}&pageSize=1&offset=2" }

      it 'returns a slice of the visible memberships' do
        expect(subject.body)
          .to be_json_eql('Collection'.to_json)
          .at_path('_type')

        expect(subject.body)
          .to be_json_eql('2')
          .at_path('total')

        expect(subject.body)
          .to be_json_eql('1')
          .at_path('count')

        expect(subject.body)
          .to be_json_eql(other_member.id.to_json)
          .at_path('_embedded/elements/0/id')
      end
    end

    context 'with a group' do
      let(:group) { FactoryBot.create(:group) }
      let(:group_member) do
        FactoryBot.create(:member,
                          roles: [FactoryBot.create(:role)],
                          project: project,
                          principal: group)
      end
      let(:members) { [own_member, group_member] }

      it 'returns that group membership together with the rest of them' do
        expect(subject.body)
          .to be_json_eql('Collection'.to_json)
          .at_path('_type')

        expect(subject.body)
          .to be_json_eql('2')
          .at_path('total')

        expect(subject.body)
          .to be_json_eql(own_member.id.to_json)
          .at_path('_embedded/elements/0/id')

        expect(subject.body)
          .to be_json_eql(group_member.id.to_json)
          .at_path('_embedded/elements/1/id')
      end
    end

    context 'filtering by user name' do
      let(:filters) do
        [{ 'any_name_attribute' => {
          'operator' => '~',
          'values' => [other_member.principal.login]
        } }]
      end

      it 'contains only the filtered member in the response' do
        expect(subject.body)
          .to be_json_eql('1')
          .at_path('total')

        expect(subject.body)
          .to be_json_eql(other_member.id.to_json)
          .at_path('_embedded/elements/0/id')
      end
    end

    context 'filtering by project' do
      let(:members) { [own_member, other_member, invisible_member, own_other_member] }

      let(:own_other_member) do
        FactoryBot.create(:member,
                          roles: [FactoryBot.create(:role, permissions: permissions)],
                          project: other_project,
                          user: current_user)
      end

      let(:other_project) { FactoryBot.create(:project) }

      let(:filters) do
        [{ 'project' => {
          'operator' => '=',
          'values' => [other_project.id]
        } }]
      end

      it 'contains only the filtered memberships in the response' do
        expect(subject.body)
          .to be_json_eql('1')
          .at_path('total')

        expect(subject.body)
          .to be_json_eql(own_other_member.id.to_json)
          .at_path('_embedded/elements/0/id')
      end
    end

    context 'filtering by principal' do
      let(:group) { FactoryBot.create(:group) }
      let(:group_member) do
        FactoryBot.create(:member,
                          roles: [FactoryBot.create(:role)],
                          principal: group,
                          project: project)
      end
      let(:members) { [own_member, other_member, group_member, invisible_member] }

      let(:filters) do
        [{ 'principal' => {
          'operator' => '=',
          'values' => [group.id.to_s, current_user.id.to_s]
        } }]
      end

      it 'contains only the filtered members in the response' do
        expect(subject.body)
          .to be_json_eql('2')
          .at_path('total')

        expect(subject.body)
          .to be_json_eql(own_member.id.to_json)
          .at_path('_embedded/elements/0/id')

        expect(subject.body)
          .to be_json_eql(group_member.id.to_json)
          .at_path('_embedded/elements/1/id')
      end
    end

    context 'invalid filter' do
      let(:members) { [own_member] }

      let(:filters) do
        [{ 'bogus' => {
          'operator' => '=',
          'values' => ['1']
        } }]
      end

      it 'returns an error' do
        expect(subject.status).to eq(400)

        expect(subject.body)
          .to be_json_eql('urn:openproject-org:api:v3:errors:InvalidQuery'.to_json)
          .at_path('errorIdentifier')
      end
    end

    context 'without permissions' do
      let(:permissions) { [] }
      it 'is empty' do
        expect(subject.body)
          .to be_json_eql('0')
          .at_path('total')
      end
    end
  end

  describe 'POST api/v3/memberships' do
    let(:path) { api_v3_paths.memberships }
    let(:principal) { other_user }
    let(:principal_path) { api_v3_paths.user(principal.id) }
    let(:body) do
      {
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
      }.to_json
    end

    before do
      own_member
      login_as current_user

      post path, body
    end

    shared_examples_for 'successful member creation' do
      it 'responds with 201' do
        expect(last_response.status).to eq(201)
      end

      it 'creates the member' do
        expect(Member.find_by(user_id: principal.id, project: project))
          .to be_present
      end

      it 'returns the newly created member' do
        expect(last_response.body)
          .to be_json_eql('Membership'.to_json)
          .at_path('_type')

        expect(last_response.body)
          .to be_json_eql(api_v3_paths.project(project.id).to_json)
          .at_path('_links/project/href')

        expect(last_response.body)
          .to be_json_eql(principal_path.to_json)
          .at_path('_links/principal/href')

        expect(last_response.body)
          .to have_json_size(1)
          .at_path('_links/roles')

        expect(last_response.body)
          .to be_json_eql(api_v3_paths.role(other_role.id).to_json)
          .at_path('_links/roles/0/href')
      end
    end

    context 'for a user' do
      it_behaves_like 'successful member creation'
    end

    context 'for a group' do
      it_behaves_like 'successful member creation' do
        let(:group) { FactoryBot.create(:group) }
        let(:principal) { group }
        let(:principal_path) { api_v3_paths.group(group.id) }
        let(:body) do
          {
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
          }.to_json
        end
      end
    end

    context 'if providing an already taken user' do
      let(:body) do
        {
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
        }.to_json
      end

      it 'responds with 422 and explains the error' do
        expect(last_response.status).to eq(422)

        expect(last_response.body)
          .to be_json_eql("User has already been taken.".to_json)
          .at_path('message')
      end
    end

    context 'if providing erroneous hrefs' do
      let(:body) do
        {
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
        }.to_json
      end

      it 'responds with 422 and explains the error' do
        expect(last_response.status).to eq(422)

        error_message = "For property 'user' a link like '/api/v3/groups/:id' or " +
                        "'/api/v3/users/:id' is expected, but got '#{api_v3_paths.role(other_user.id)}'."

        expect(last_response.body)
          .to be_json_eql(error_message.to_json)
          .at_path('message')
      end
    end

    context 'if lacking the manage permissions' do
      let(:permissions) { [:view_members] }

      it_behaves_like 'unauthorized access'
    end
  end

  describe 'GET /api/v3/memberships/:id' do
    let(:path) { api_v3_paths.membership(other_member.id) }

    let(:members) { [own_member, other_member] }

    before do
      members

      login_as(current_user)

      get path
    end

    it 'returns 200 OK' do
      expect(subject.status)
        .to eql(200)
    end

    it 'returns the member' do
      expect(subject.body)
        .to be_json_eql('Membership'.to_json)
        .at_path('_type')

      expect(subject.body)
        .to be_json_eql(other_member.id.to_json)
        .at_path('id')
    end

    context 'if querying an invisible member' do
      let(:path) { api_v3_paths.membership(invisible_member.id) }

      let(:members) { [own_member, invisible_member] }

      it 'returns 404 NOT FOUND' do
        expect(subject.status)
          .to eql(404)
      end
    end

    context 'without the necessary permissions' do
      let(:permissions) { [] }

      it 'returns 404 NOT FOUND' do
        expect(subject.status)
          .to eql(404)
      end
    end
  end

  describe 'PATCH api/v3/memberships/:id' do
    let(:path) { api_v3_paths.membership(other_member.id) }
    let(:another_role) { FactoryBot.create(:role) }
    let(:body) do
      {
        _links: {
          "roles": [
            {
              href: api_v3_paths.role(another_role.id)
            }
          ]
        }
      }.to_json
    end

    let(:members) { [own_member, other_member] }

    before do
      members

      login_as current_user

      patch path, body
    end

    it 'responds with 200' do
      expect(last_response.status).to eq(200)
    end

    it 'updates the member' do
      expect(other_member.roles.reload)
        .to match_array [another_role]
    end

    it 'returns the updated version' do
      expect(last_response.body)
        .to be_json_eql('Membership'.to_json)
        .at_path('_type')

      expect(last_response.body)
        .to be_json_eql([{ href: api_v3_paths.role(another_role.id), title: another_role.name }].to_json)
        .at_path('_links/roles')

      # unchanged
      expect(last_response.body)
        .to be_json_eql(project.name.to_json)
        .at_path('_links/project/title')

      expect(last_response.body)
        .to be_json_eql(other_user.name.to_json)
        .at_path('_links/principal/title')
    end

    context 'if attempting to empty the roles' do
      let(:body) do
        {
          _links: {
            "roles": []
          }
        }.to_json
      end

      it 'returns 422' do
        expect(last_response.status)
          .to eql(422)

        expect(last_response.body)
          .to be_json_eql("Roles need to be assigned.".to_json)
          .at_path('message')
      end
    end

    context 'if attempting to assign unassignable roles' do
      let(:anonymous_role) { FactoryBot.create(:anonymous_role) }
      let(:body) do
        {
          _links: {
            "roles": [
              {
                href: api_v3_paths.role(anonymous_role.id)
              }
            ]
          }
        }.to_json
      end

      it 'returns 422' do
        expect(last_response.status)
          .to eql(422)

        expect(last_response.body)
          .to be_json_eql("Roles has an unassignable role.".to_json)
          .at_path('message')
      end
    end

    context 'if attempting to switch the project' do
      let(:other_project) do
        FactoryBot.create(:project).tap do |p|
          FactoryBot.create(:member,
                            project: p,
                            roles: [FactoryBot.create(:role, permissions: [:manage_members])],
                            user: current_user)
        end
      end

      let(:body) do
        {
          _links: {
            "project": {
              "href": api_v3_paths.project(other_project.id)

            }
          }
        }.to_json
      end

      it_behaves_like 'read-only violation', 'project', Member
    end

    context 'if attempting to switch the principal' do
      let(:another_user) do
        FactoryBot.create(:user)
      end

      let(:body) do
        {
          _links: {
            "principal": {
              "href": api_v3_paths.user(another_user.id)

            }
          }
        }.to_json
      end

      it_behaves_like 'read-only violation', 'user', Member
    end

    context 'if lacking the manage permissions' do
      let(:permissions) { [:view_members] }

      it_behaves_like 'unauthorized access'
    end

    context 'if lacking the view permissions' do
      let(:permissions) { [] }

      it_behaves_like 'not found' do
        let(:id) { member.id }
        let(:type) { 'Membership' }
      end
    end
  end

  describe 'DELETE /api/v3/memberships/:id' do
    let(:path) { api_v3_paths.membership(other_member.id) }
    let(:members) { [own_member, other_member] }

    before do
      members
      login_as current_user

      delete path
    end

    subject { last_response }

    context 'with required permissions' do
      it 'responds with HTTP No Content' do
        expect(subject.status).to eq 204
      end

      it 'deletes the member' do
        expect(Member.exists?(other_member.id)).to be_falsey
      end

      context 'for a non-existent version' do
        let(:path) { api_v3_paths.membership 1337 }

        it_behaves_like 'not found' do
          let(:id) { 1337 }
          let(:type) { 'Membership' }
        end
      end
    end

    context 'without permission to delete members' do
      let(:permissions) { [:view_members] }

      it_behaves_like 'unauthorized access'

      it 'does not delete the member' do
        expect(Member.exists?(other_member.id)).to be_truthy
      end
    end
  end
end
