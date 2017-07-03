#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe 'API v3 Principals resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  describe '#get principals' do
    let(:path) { api_v3_paths.principals }
    let(:project) { FactoryGirl.create(:project) }
    let(:other_project) { FactoryGirl.create(:project) }
    let(:non_member_project) { FactoryGirl.create(:project) }
    let(:role) { FactoryGirl.create(:role, permissions: permissions) }
    let(:permissions) { [] }
    let(:user) do
      user = FactoryGirl.create(:user,
                                member_in_project: project,
                                member_through_role: role)

      other_project.add_member! user, role

      user
    end
    let(:other_user) do
      FactoryGirl.create(:user,
                         member_in_project: other_project,
                         member_through_role: role)
    end
    let(:user_in_non_member_project) do
      FactoryGirl.create(:user,
                         member_in_project: non_member_project,
                         member_through_role: role)
    end
    let(:group) do
      group = FactoryGirl.create(:group)

      project.add_member! group, role

      user
    end

    before do
      allow(User)
        .to receive(:current)
        .and_return(user)

      other_user
      user_in_non_member_project
      group

      get path
    end

    it 'succeeds' do
      expect(last_response.status)
        .to eql(200)
    end

    it_behaves_like 'API V3 collection response', 3, 3, 'User' do
      let(:response) { last_response }
    end

    context 'provide filter for project the user is member in' do
      let(:filter) do
        [{ member: { operator: '=', values: [project.id.to_s] } }]
      end

      let(:path) do
        "#{api_v3_paths.principals}?filters=#{CGI.escape(JSON.dump(filter))}"
      end

      it_behaves_like 'API V3 collection response', 2, 2, 'User' do
        let(:response) { last_response }
      end
    end

    context 'provide filter for type "User"' do
      let(:filter) do
        [{ type: { operator: '=', values: ['User'] } }]
      end

      let(:path) do
        "#{api_v3_paths.principals}?filters=#{CGI.escape(JSON.dump(filter))}"
      end

      it_behaves_like 'API V3 collection response', 2, 2, 'User' do
        let(:response) { last_response }
      end
    end

    context 'provide filter for type "Group"' do
      let(:filter) do
        [{ type: { operator: '=', values: ['Group'] } }]
      end

      let(:path) do
        "#{api_v3_paths.principals}?filters=#{CGI.escape(JSON.dump(filter))}"
      end

      it_behaves_like 'API V3 collection response', 1, 1, 'User' do
        let(:response) { last_response }
      end
    end

    context 'user without a project membership' do
      let(:user) { FactoryGirl.create(:user) }

      # The user herself
      it_behaves_like 'API V3 collection response', 1, 1, 'User' do
        let(:response) { last_response }
      end
    end
  end
end
