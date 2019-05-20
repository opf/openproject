#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe 'API v3 members resource', type: :request do
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
  let(:other_member) do
    FactoryBot.create(:member,
                      roles: [FactoryBot.create(:role)],
                      project: project)
  end
  let(:invisible_member) do
    FactoryBot.create(:member,
                      roles: [FactoryBot.create(:role)])
  end

  subject(:response) { last_response }

  describe 'GET api/v3/members' do
    let(:members) { [own_member, other_member, invisible_member] }

    before do
      members

      login_as(current_user)

      get path
    end

    let(:path) { api_v3_paths.members }

    context 'without params' do
      it 'responds 200 OK' do
        expect(subject.status).to eq(200)
      end

      it 'returns a collection of members containing only the visible ones' do
        expect(subject.body)
          .to be_json_eql('Collection'.to_json)
          .at_path('_type')

        # the one member stems from the membership the user has himself
        expect(subject.body)
          .to be_json_eql('2')
          .at_path('total')

        expect(subject.body)
          .to be_json_eql(other_member.id.to_json)
          .at_path('_embedded/elements/0/id')

        expect(subject.body)
          .to be_json_eql(own_member.id.to_json)
          .at_path('_embedded/elements/1/id')
      end
    end

    context 'with pageSize, offset and sortBy' do
      let(:path) { "#{api_v3_paths.members}?pageSize=1&offset=2&sortBy=#{[%i(id asc)].to_json}" }

      it 'returns a slice of the visible members' do
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
          .to be_json_eql(group_member.id.to_json)
          .at_path('_embedded/elements/0/id')

        expect(subject.body)
          .to be_json_eql(own_member.id.to_json)
          .at_path('_embedded/elements/1/id')
      end
    end

    context 'filtering by user name' do
      let(:path) do
        filter = [{ 'any_name_attribute' => {
          'operator' => '~',
          'values' => [other_member.user.login]
        } }]

        "#{api_v3_paths.members}?#{{ filters: filter.to_json }.to_query}"
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

      let(:path) do
        filter = [{ 'project' => {
          'operator' => '=',
          'values' => [other_project.id]
        } }]

        "#{api_v3_paths.members}?#{{ filters: filter.to_json }.to_query}"
      end

      it 'contains only the filtered members in the response' do
        expect(subject.body)
          .to be_json_eql('1')
          .at_path('total')

        expect(subject.body)
          .to be_json_eql(own_other_member.id.to_json)
          .at_path('_embedded/elements/0/id')
      end
    end

    context 'invalid filter' do
      let(:members) { [own_member] }

      let(:path) do
        filter = [{ 'bogus' => {
          'operator' => '=',
          'values' => ['1']
        } }]

        "#{api_v3_paths.members}?#{{ filters: filter.to_json }.to_query}"
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

  #describe 'GET /api/v3/time_entries/:id' do
    #let(:path) { api_v3_paths.time_entry(time_entry.id) }

    #before do
    #  time_entry
    #  custom_value

    #  get path
    #end

    #it 'returns 200 OK' do
    #  expect(subject.status)
    #    .to eql(200)
    #end

    #it 'returns the time entry' do
    #  expect(subject.body)
    #    .to be_json_eql('TimeEntry'.to_json)
    #          .at_path('_type')

    #  expect(subject.body)
    #    .to be_json_eql(time_entry.id.to_json)
    #          .at_path('id')

    #  expect(subject.body)
    #    .to be_json_eql(custom_value.value.to_json)
    #          .at_path("customField#{custom_field.id}/raw")
    #end

    #context 'when lacking permissions' do
    #  let(:permissions) { [] }

    #  it 'returns 404 NOT FOUND' do
    #    expect(subject.status)
    #      .to eql(404)
    #  end
    #end
  #end
end
