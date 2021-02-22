#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe 'API v3 Group resource', type: :request, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  subject(:response) { last_response }

  shared_let(:project) { FactoryBot.create(:project) }
  let(:group) do
    FactoryBot.create(:group,
                      member_in_project: project,
                      member_through_role: role).tap do |g|
      members.each do |members|
        GroupUser.create group_id: g.id, user_id: members.id
      end
    end
  end
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) { %i[view_members manage_members] }
  let(:members) do
    FactoryBot.create_list(:user, 2)
  end

  current_user do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end

  describe 'GET api/v3/groups/:id' do
    let(:get_path) { api_v3_paths.group group.id }

    before do
      get get_path
    end

    context 'having the necessary permission' do
      it 'responds with 200 OK' do
        expect(subject.status)
          .to eq(200)
      end

      it 'responds with the correct group resource including the members' do
        expect(subject.body)
          .to be_json_eql('Group'.to_json)
          .at_path('_type')

        expect(subject.body)
          .to be_json_eql(group.name.to_json)
          .at_path('name')

        expect(JSON::parse(subject.body).dig('_links', 'members').map { |link| link['href'] })
          .to match_array members.map { |m| api_v3_paths.user(m.id) }
      end
    end

    context 'requesting nonexistent group' do
      let(:get_path) { api_v3_paths.group 9999 }

      it_behaves_like 'not found' do
        let(:id) { 9999 }
        let(:type) { 'Group' }
      end
    end

    context 'not having the necessary permission to see any group' do
      let(:permissions) { [] }

      it_behaves_like 'unauthorized access'
    end

    context 'not having the necessary permission to see the specific group' do
      let(:permissions) { %i[view_members] }
      let(:group) { FactoryBot.create(:group) }

      it_behaves_like 'not found'
    end
  end

  describe 'POST api/v3/groups' do
    let(:path) { api_v3_paths.groups }
    let(:body) do
      {
        name: 'The new group',
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

    before do
      post path, body
    end

    context 'when the user is allowed and the input is valid' do
      current_user { FactoryBot.create(:admin) }

      it 'responds with 201' do
        expect(last_response.status).to eq(201)
      end

      it 'creates the group and sets the members' do
        group = Group.find_by(name: 'The new group')
        expect(group)
          .to be_present

        expect(group.users)
          .to match_array members
      end

      it 'returns the newly created group' do
        expect(last_response.body)
          .to be_json_eql('Group'.to_json)
          .at_path('_type')

        expect(last_response.body)
          .to be_json_eql('The new group'.to_json)
          .at_path('name')
      end
    end

    context 'when the user is allowed and the input is invalid' do
      current_user { FactoryBot.create(:admin) }

      let(:body) do
        {
          name: ''
        }.to_json
      end

      it 'responds with 422 and explains the error' do
        expect(last_response.status).to eq(422)

        expect(last_response.body)
          .to be_json_eql("Name can't be blank.".to_json)
          .at_path('message')
      end
    end

    context 'not having the necessary permission' do
      it_behaves_like 'unauthorized access'
    end
  end

  describe 'PATCH api/v3/groups/:id' do
    let(:path) { api_v3_paths.group(group.id) }
    let(:another_user) { FactoryBot.create(:user) }
    let(:body) do
      {
        _links: {
          "members": [
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
    let(:other_project) { FactoryBot.create(:project) }
    let!(:membership) do
      FactoryBot.create(:member,
                        principal: group,
                        project: other_project,
                        roles: [FactoryBot.create(:role)])
    end
    let(:admin) { FactoryBot.create(:admin) }

    before do
      # Setup the memberships in the group has
      ::Groups::AddUsersService
        .new(group, current_user: admin)
        .call(ids: members.map(&:id))

      group_updated_at

      login_as current_user

      patch path, body
    end

    context 'when the user is allowed and the input is valid' do
      current_user { admin }

      it 'responds with 200' do
        expect(last_response.status).to eq(200)
      end

      it 'updates the group' do
        group.reload

        expect(group.users)
          .to match_array [members.last, another_user]

        # Altering only the members still updates the group's timestamp
        expect(group.updated_at > group_updated_at)
          .to be_truthy
      end

      it 'returns the updated group' do
        expect(last_response.body)
          .to be_json_eql('Group'.to_json)
          .at_path('_type')

        expect(last_response.body)
          .to be_json_eql([{ href: api_v3_paths.user(members.last.id), title: members.last.name },
                           { href: api_v3_paths.user(another_user.id), title: another_user.name }].to_json)
          .at_path('_links/members')

        # unchanged
        expect(last_response.body)
          .to be_json_eql(group.name.to_json)
          .at_path('name')

        # includes the memberships the group has applied to the added user
        expect(other_project.reload.users)
          .to match_array [members.last, another_user]
      end
    end

    context 'if attempting to set an empty name' do
      current_user { admin }

      let(:body) do
        {
          _links: {
            "members": [
              {
                href: api_v3_paths.user(members.last.id)
              },
              {
                href: api_v3_paths.user(another_user.id)
              }
            ]
          },
          name: ''
        }.to_json
      end

      it 'returns 422' do
        expect(last_response.status)
          .to eql(422)

        expect(last_response.body)
          .to be_json_eql("Name can't be blank.".to_json)
          .at_path('message')
      end

      it 'does not alter the group' do
        group.reload

        expect(group.users)
          .to match_array members

        expect(group.updated_at)
          .to eql group_updated_at
      end
    end

    context 'when not being an admin' do
      let(:permissions) { [:manage_members] }

      it_behaves_like 'unauthorized access'
    end

    context 'when lacking the view permissions' do
      let(:permissions) { [] }

      it_behaves_like 'unauthorized access'
    end
  end

  describe 'GET api/v3/groups' do
    let(:get_path) { api_v3_paths.groups }
    let(:other_group) do
      FactoryBot.create(:group)
    end

    before do
      group
      other_group

      get get_path
    end

    context 'having the necessary permission' do
      it 'responds with 200 OK' do
        expect(subject.status)
          .to eq(200)
      end

      it 'responds with a collection of groups' do
        expect(subject.body)
          .to be_json_eql('Collection'.to_json)
          .at_path('_type')

        expect(subject.body)
          .to be_json_eql('2')
          .at_path('total')

        expect(subject.body)
          .to be_json_eql(other_group.id.to_json)
          .at_path('_embedded/elements/0/id')

        expect(subject.body)
          .to be_json_eql(group.id.to_json)
          .at_path('_embedded/elements/1/id')
      end
    end

    context 'not having the necessary permission' do
      let(:permissions) { [] }

      it_behaves_like 'unauthorized access'
    end
  end
end
