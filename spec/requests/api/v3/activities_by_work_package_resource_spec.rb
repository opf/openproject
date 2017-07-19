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

describe API::V3::Activities::ActivitiesByWorkPackageAPI, type: :request do
  include API::V3::Utilities::PathHelper

  describe 'activities' do
    let(:project) { work_package.project }
    let(:work_package) { FactoryGirl.create(:work_package) }
    let(:comment) { 'This is a test comment!' }
    let(:current_user) do
      FactoryGirl.create(:user, member_in_project: project, member_through_role: role)
    end
    let(:role) { FactoryGirl.create(:role, permissions: permissions) }
    let(:permissions) { %i(view_work_packages add_work_package_notes) }

    before do
      allow(User).to receive(:current).and_return(current_user)
    end

    describe 'GET /api/v3/work_packages/:id/activities' do
      before do
        get api_v3_paths.work_package_activities work_package.id
      end

      it 'succeeds' do
        expect(response.status).to eql 200
      end

      context 'not allowed to see work package' do
        let(:current_user) { FactoryGirl.create(:user) }

        it 'fails with HTTP Not Found' do
          expect(response.status).to eql 404
        end
      end
    end

    describe 'POST /api/v3/work_packages/:id/activities' do
      let(:work_package) { FactoryGirl.create(:work_package) }

      shared_context 'create activity' do
        before do
          post api_v3_paths.work_package_activities(work_package.id),
               params: { comment: { raw: comment } }.to_json,
               headers: { 'CONTENT_TYPE' => 'application/json' }
        end
      end

      it_behaves_like 'safeguarded API' do
        let(:permissions) { %i(view_work_packages) }

        include_context 'create activity'
      end

      it_behaves_like 'valid activity request' do
        let(:status_code) { 201 }

        include_context 'create activity'
      end

      context 'with an errorenous work package' do
        before do
          work_package.subject = ''
          work_package.save!(validate: false)
        end

        include_context 'create activity'

        it 'responds with error' do
          expect(response.status).to eql 422
        end

        it 'notes the error' do
          expect(response.body)
            .to be_json_eql("Subject can't be blank.".to_json)
            .at_path('message')
        end
      end
    end
  end
end
