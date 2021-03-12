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

describe 'API v3 capabilities resource', type: :request, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  subject(:response) { last_response }

  current_user do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: current_user_permissions)
  end
  let(:current_user_permissions) { [] }
  let(:other_user_permissions) { %i[manage_members] }
  let(:other_user_global_permissions) { %i[manage_user] }
  let(:project) { FactoryBot.create(:project) }
  let(:role) do
    FactoryBot.create(:role, permissions: other_user_permissions)
  end
  let(:global_role) do
    FactoryBot.create(:global_role, permissions: other_user_global_permissions)
  end
  let(:other_user) { FactoryBot.create(:user) }
  let(:other_user_global_member) do
    FactoryBot.create(:global_member,
                      principal: other_user,
                      roles: [global_role])
  end
  let(:other_user_member) do
    FactoryBot.create(:member,
                      principal: other_user,
                      roles: [role],
                      project: project)
  end

  describe 'GET api/v3/capabilities' do
    let(:setup) do
      other_user_global_member
      other_user_member
    end
    let(:filters) { nil }
    let(:path) { api_v3_paths.path_for(:capabilities, filters: filters, sort_by: [%i(id asc)]) }

    before do
      setup

      get path
    end

    context 'without params' do
      it 'responds 200 OK' do
        expect(subject.status).to eq(200)
      end

      it 'returns a collection of capabilities' do
        expect(subject.body)
          .to be_json_eql('Collection'.to_json)
          .at_path('_type')

        expect(subject.body)
          .to be_json_eql('3')
          .at_path('total')

        expect(subject.body)
          .to be_json_eql("memberships/create/p#{project.id}-#{other_user.id}".to_json)
          .at_path('_embedded/elements/0/id')

        expect(subject.body)
          .to be_json_eql("users/create/g-#{other_user.id}".to_json)
          .at_path('_embedded/elements/1/id')

        expect(subject.body)
          .to be_json_eql("users/update/g-#{other_user.id}".to_json)
          .at_path('_embedded/elements/2/id')
      end
    end

    #context 'as an admin' do
    #  let(:current_user) { admin }

    #  it 'returns a collection of memberships containing only the visible ones', :aggregate_failures do
    #    expect(subject.status).to eq(200)

    #    expect(subject.body)
    #      .to be_json_eql('Collection'.to_json)
    #            .at_path('_type')

    #    # the one membership stems from the membership the user has himself
    #    expect(subject.body)
    #      .to be_json_eql('4')
    #            .at_path('total')

    #    expect(subject.body)
    #      .to be_json_eql(own_member.id.to_json)
    #            .at_path('_embedded/elements/0/id')

    #    expect(subject.body)
    #      .to be_json_eql(other_member.id.to_json)
    #            .at_path('_embedded/elements/1/id')

    #    expect(subject.body)
    #      .to be_json_eql(invisible_member.id.to_json)
    #            .at_path('_embedded/elements/2/id')

    #    expect(subject.body)
    #      .to be_json_eql(global_member.id.to_json)
    #            .at_path('_embedded/elements/3/id')
    #  end
    #end

    context 'with pageSize, offset and sortBy' do
      let(:path) { "#{api_v3_paths.path_for(:capabilities, sort_by: [%i(id asc)])}&pageSize=1&offset=2" }

      it 'returns a slice of the visible memberships' do
        expect(subject.body)
          .to be_json_eql('Collection'.to_json)
          .at_path('_type')

        expect(subject.body)
          .to be_json_eql('3')
          .at_path('total')

        expect(subject.body)
          .to be_json_eql('1')
          .at_path('count')

        expect(subject.body)
          .to be_json_eql("users/create/g-#{other_user.id}".to_json)
          .at_path('_embedded/elements/0/id')
      end
    end

    #context 'with a group' do
    #  let(:group) { FactoryBot.create(:group) }
    #  let(:group_member) do
    #    FactoryBot.create(:member,
    #                      roles: [FactoryBot.create(:role)],
    #                      project: project,
    #                      principal: group)
    #  end
    #  let(:members) { [own_member, group_member] }

    #  it 'returns that group membership together with the rest of them' do
    #    expect(subject.body)
    #      .to be_json_eql('Collection'.to_json)
    #            .at_path('_type')

    #    expect(subject.body)
    #      .to be_json_eql('2')
    #            .at_path('total')

    #    expect(subject.body)
    #      .to be_json_eql(own_member.id.to_json)
    #            .at_path('_embedded/elements/0/id')

    #    expect(subject.body)
    #      .to be_json_eql(group_member.id.to_json)
    #            .at_path('_embedded/elements/1/id')
    #  end
    #end

    #context 'with a placeholder_user' do
    #  let(:placeholder_user) do
    #    FactoryBot.create(:placeholder_user)
    #  end
    #  let(:placeholder_member) do
    #    FactoryBot.create(:member,
    #                      roles: [FactoryBot.create(:role)],
    #                      project: project,
    #                      principal: placeholder_user)
    #  end
    #  let(:members) { [own_member, placeholder_member] }

    #  it 'returns that placeholder user membership together with the rest of them' do
    #    expect(subject.body)
    #      .to be_json_eql('Collection'.to_json)
    #            .at_path('_type')

    #    expect(subject.body)
    #      .to be_json_eql('2')
    #            .at_path('total')

    #    expect(subject.body)
    #      .to be_json_eql(own_member.id.to_json)
    #            .at_path('_embedded/elements/0/id')

    #    expect(subject.body)
    #      .to be_json_eql(placeholder_member.id.to_json)
    #            .at_path('_embedded/elements/1/id')
    #  end
    #end

    #context 'filtering by user name' do
    #  let(:filters) do
    #    [{ 'any_name_attribute' => {
    #      'operator' => '~',
    #      'values' => [other_member.principal.login]
    #    } }]
    #  end

    #  it 'contains only the filtered member in the response' do
    #    expect(subject.body)
    #      .to be_json_eql('1')
    #            .at_path('total')

    #    expect(subject.body)
    #      .to be_json_eql(other_member.id.to_json)
    #            .at_path('_embedded/elements/0/id')
    #  end
    #end

    #context 'filtering by project' do
    #  let(:members) { [own_member, other_member, invisible_member, own_other_member] }

    #  let(:own_other_member) do
    #    FactoryBot.create(:member,
    #                      roles: [FactoryBot.create(:role, permissions: permissions)],
    #                      project: other_project,
    #                      user: current_user)
    #  end

    #  let(:other_project) { FactoryBot.create(:project) }

    #  let(:filters) do
    #    [{ 'project' => {
    #      'operator' => '=',
    #      'values' => [other_project.id]
    #    } }]
    #  end

    #  it 'contains only the filtered memberships in the response' do
    #    expect(subject.body)
    #      .to be_json_eql('1')
    #            .at_path('total')

    #    expect(subject.body)
    #      .to be_json_eql(own_other_member.id.to_json)
    #            .at_path('_embedded/elements/0/id')
    #  end
    #end

    #context 'filtering by principal' do
    #  let(:group) { FactoryBot.create(:group) }
    #  let(:group_member) do
    #    FactoryBot.create(:member,
    #                      roles: [FactoryBot.create(:role)],
    #                      principal: group,
    #                      project: project)
    #  end
    #  let(:members) { [own_member, other_member, group_member, invisible_member] }

    #  let(:filters) do
    #    [{ 'principal' => {
    #      'operator' => '=',
    #      'values' => [group.id.to_s, current_user.id.to_s]
    #    } }]
    #  end

    #  it 'contains only the filtered members in the response' do
    #    expect(subject.body)
    #      .to be_json_eql('2')
    #            .at_path('total')

    #    expect(subject.body)
    #      .to be_json_eql(own_member.id.to_json)
    #            .at_path('_embedded/elements/0/id')

    #    expect(subject.body)
    #      .to be_json_eql(group_member.id.to_json)
    #            .at_path('_embedded/elements/1/id')
    #  end
    #end

    #context 'with the outdated created_on sort by (renamed to created_at)' do
    #  let(:path) { "#{api_v3_paths.path_for(:memberships, sort_by: [%i(created_on desc)])}&pageSize=1&offset=2" }

    #  it 'is still supported and returns a slice of the visible memberships' do
    #    expect(subject.body)
    #      .to be_json_eql('Collection'.to_json)
    #            .at_path('_type')

    #    expect(subject.body)
    #      .to be_json_eql('2')
    #            .at_path('total')

    #    expect(subject.body)
    #      .to be_json_eql('1')
    #            .at_path('count')

    #    expect(subject.body)
    #      .to be_json_eql(own_member.id.to_json)
    #            .at_path('_embedded/elements/0/id')
    #  end
    #end

    #context 'invalid filter' do
    #  let(:members) { [own_member] }

    #  let(:filters) do
    #    [{ 'bogus' => {
    #      'operator' => '=',
    #      'values' => ['1']
    #    } }]
    #  end

    #  it 'returns an error' do
    #    expect(subject.status).to eq(400)

    #    expect(subject.body)
    #      .to be_json_eql('urn:openproject-org:api:v3:errors:InvalidQuery'.to_json)
    #            .at_path('errorIdentifier')
    #  end
    #end

    #context 'without permissions' do
    #  let(:permissions) { [] }
    #  it 'is empty' do
    #    expect(subject.body)
    #      .to be_json_eql('0')
    #            .at_path('total')
    #  end
    #end
  end

  #describe 'GET /api/v3/memberships/:id' do
  #  let(:path) { api_v3_paths.membership(other_member.id) }

  #  let(:members) { [own_member, other_member] }

  #  before do
  #    members

  #    login_as(current_user)

  #    get path
  #  end

  #  it 'returns 200 OK' do
  #    expect(subject.status)
  #      .to eql(200)
  #  end

  #  it 'returns the member' do
  #    expect(subject.body)
  #      .to be_json_eql('Membership'.to_json)
  #            .at_path('_type')

  #    expect(subject.body)
  #      .to be_json_eql(other_member.id.to_json)
  #            .at_path('id')
  #  end

  #  context 'if querying an invisible member' do
  #    let(:path) { api_v3_paths.membership(invisible_member.id) }

  #    let(:members) { [own_member, invisible_member] }

  #    it 'returns 404 NOT FOUND' do
  #      expect(subject.status)
  #        .to eql(404)
  #    end
  #  end

  #  context 'without the necessary permissions' do
  #    let(:permissions) { [] }

  #    it 'returns 404 NOT FOUND' do
  #      expect(subject.status)
  #        .to eql(404)
  #    end
  #  end
  #end
end
