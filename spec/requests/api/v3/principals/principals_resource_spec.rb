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

describe 'API v3 Principals resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  describe '#get principals' do
    let(:path) do
      path = api_v3_paths.principals

      query_props = []

      if order
        query_props << "sortBy=#{JSON.dump(order.map { |(k, v)| [k, v] })}"
      end

      if filter
        query_props << "filters=#{CGI.escape(JSON.dump(filter))}"
      end

      "#{path}?#{query_props.join('&')}"
    end
    let(:order) { { name: :desc } }
    let(:filter) { nil }
    let(:project) { FactoryBot.create(:project) }
    let(:other_project) { FactoryBot.create(:project) }
    let(:non_member_project) { FactoryBot.create(:project) }
    let(:role) { FactoryBot.create(:role, permissions: permissions) }
    let(:permissions) { [] }
    let(:user) do
      user = FactoryBot.create(:user,
                               member_in_project: project,
                               member_through_role: role,
                               lastname: 'Aaaa')

      other_project.add_member! user, role

      user
    end
    let!(:other_user) do
      FactoryBot.create(:user,
                        member_in_project: other_project,
                        member_through_role: role,
                        lastname: 'Bbbb')
    end
    let!(:user_in_non_member_project) do
      FactoryBot.create(:user,
                        member_in_project: non_member_project,
                        member_through_role: role,
                        lastname: 'Cccc')
    end
    let!(:group) do
      group = FactoryBot.create(:group,
                                lastname: 'Gggg')

      project.add_member! group, role

      user
    end
    let!(:placeholder_user) do
      placeholder = FactoryBot.create(:placeholder_user,
                                      name: 'Pppp')

      project.add_member! placeholder, role

      user
    end

    before do
      login_as(user)

      get path
    end

    it 'succeeds' do
      expect(last_response.status)
        .to eql(200)
    end

    it_behaves_like 'API V3 collection response', 4, 4 do
      let(:response) { last_response }

      it 'has the group as the last and the placeholder as the second to last element', :aggregate_failures do
        is_expected
          .to be_json_eql('PlaceholderUser'.to_json)
          .at_path('_embedded/elements/0/_type')

        is_expected
          .to be_json_eql('Group'.to_json)
          .at_path('_embedded/elements/1/_type')

        is_expected
            .to be_json_eql('User'.to_json)
                    .at_path('_embedded/elements/2/_type')
      end
    end

    context 'provide filter for project the user is member in' do
      let(:filter) do
        [{ member: { operator: '=', values: [project.id.to_s] } }]
      end

      it_behaves_like 'API V3 collection response', 3, 3 do
        let(:response) { last_response }
      end
    end

    context 'provide filter for type "User"' do
      let(:filter) do
        [{ type: { operator: '=', values: ['User'] } }]
      end

      it_behaves_like 'API V3 collection response', 2, 2, nil do
        let(:response) { last_response }
      end
    end

    context 'provide filter for type "Group"' do
      let(:filter) do
        [{ type: { operator: '=', values: ['Group'] } }]
      end

      it_behaves_like 'API V3 collection response', 1, 1, 'Group' do
        let(:response) { last_response }
      end
    end

    context 'provide filter for type "PlaceholderUser"' do
      let(:filter) do
        [{ type: { operator: '=', values: ['PlaceholderUser'] } }]
      end

      it_behaves_like 'API V3 collection response', 1, 1, 'PlaceholderUser' do
        let(:response) { last_response }
      end
    end

    context 'user without a project membership' do
      let(:user) { FactoryBot.create(:user) }

      # The user herself
      it_behaves_like 'API V3 collection response', 1, 1, 'User' do
        let(:response) { last_response }
      end
    end
  end
end
