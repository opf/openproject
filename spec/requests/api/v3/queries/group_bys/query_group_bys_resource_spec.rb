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

describe 'API v3 Query Group By resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  describe '#get queries/group_bys/:id' do
    let(:path) { api_v3_paths.query_group_by(group_by_name) }
    let(:group_by_name) { 'status' }
    let(:project) { FactoryBot.create(:project) }
    let(:role) { FactoryBot.create(:role, permissions: permissions) }
    let(:permissions) { [:view_work_packages] }
    let(:user) do
      FactoryBot.create(:user,
                         member_in_project: project,
                         member_through_role: role)
    end

    before do
      allow(User)
        .to receive(:current)
        .and_return(user)

      get path
    end

    it 'succeeds' do
      expect(last_response.status)
        .to eql(200)
    end

    it 'returns the group_by' do
      expect(last_response.body)
        .to be_json_eql(path.to_json)
        .at_path('_links/self/href')
    end

    context 'user not allowed' do
      let(:permissions) { [] }

      it_behaves_like 'unauthorized access'
    end

    context 'non existing group by' do
      let(:path) { api_v3_paths.query_group_by('bogus') }

      it 'returns 404' do
        expect(last_response.status)
          .to eql(404)
      end
    end

    context 'non groupable group by' do
      let(:path) { api_v3_paths.query_group_by('id') }

      it 'returns 404' do
        expect(last_response.status)
          .to eql(404)
      end
    end
  end
end
