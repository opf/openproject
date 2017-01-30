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

describe 'API v3 Query Sort Bys resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  describe '#get queries/sort_bys/:id' do
    let(:path) { api_v3_paths.query_sort_by(column_name, direction) }
    let(:column_name) { 'status' }
    let(:direction) { 'desc' }
    let(:project) { FactoryGirl.create(:project) }
    let(:role) { FactoryGirl.create(:role, permissions: permissions) }
    let(:permissions) { [:view_work_packages] }
    let(:user) do
      FactoryGirl.create(:user,
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
        .to eq(200)
    end

    it 'returns the sort by' do
      expect(last_response.body)
        .to be_json_eql(path.to_json)
        .at_path('_links/self/href')
    end

    context 'user not allowed' do
      let(:permissions) { [] }

      it_behaves_like 'unauthorized access'
    end

    context 'non existing sort by' do
      let(:path) { api_v3_paths.query_sort_by('bogus', direction) }

      it 'returns 404' do
        expect(last_response.status)
          .to eql(404)
      end
    end

    context 'non existing direction' do
      let(:path) { api_v3_paths.query_sort_by(column_name, 'bogus') }

      it 'returns 404' do
        expect(last_response.status)
          .to eql(404)
      end
    end

    context 'non sortable sort by' do
      let(:path) { api_v3_paths.query_sort_by('spent_time', direction) }

      it 'returns 404' do
        expect(last_response.status)
          .to eql(404)
      end
    end
  end
end
