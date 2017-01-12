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

describe API::V3::WorkPackages::Schema::WorkPackageSchemasAPI, type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:path) { api_v3_paths.work_package_columns project.id }
  let(:current_user) {
    FactoryGirl.build(:user, member_in_project: project, member_through_role: role)
  }
  let(:role) { FactoryGirl.build(:role, permissions: permissions) }
  let(:permissions) { [:view_work_packages] }

  describe 'GET /api/v3/projects/:id/work_packages/columns' do
    before do
      allow(User).to receive(:current).and_return(current_user)
      get path
    end

    it 'should return HTTP OK' do
      expect(last_response.status).to eql(200)
    end

    it 'should not contain the lockVersion' do
      expect(last_response.body).not_to have_json_path('lockVersion')
    end

    context 'not allowed to see the project' do
      let(:current_user) { FactoryGirl.create(:user) }

      it 'should return HTTP Not Found' do
        expect(last_response.status).to eql(404)
      end
    end

    context 'not allowed to see work packages' do
      let(:permissions) { [] }

      it 'should return HTTP Forbidden' do
        expect(last_response.status).to eql(403)
      end
    end
  end
end
