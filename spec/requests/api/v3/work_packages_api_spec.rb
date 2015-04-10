#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe API::V3::WorkPackages::WorkPackagesAPI, type: :request do
  include API::V3::Utilities::PathHelper

  let(:admin) { FactoryGirl.create(:admin) }

  describe 'activities' do
    let(:work_package) { FactoryGirl.create(:work_package) }
    let(:comment) { 'This is a test comment!' }

    describe 'POST /api/v3/work_packages/:id/activities' do
      shared_context 'create activity' do
        before {
          post (api_v3_paths.work_package_activities work_package.id),
               { comment: comment }.to_json,  'CONTENT_TYPE' => 'application/json'
        }
      end

      it_behaves_like 'safeguarded API' do
        include_context 'create activity'
      end

      it_behaves_like 'valid activity request' do
        let(:status_code) { 201 }

        include_context 'create activity'
      end

      it_behaves_like 'invalid activity request' do
        before { allow_any_instance_of(WorkPackage).to receive(:save).and_return(false) }

        include_context 'create activity'
      end
    end
  end
end
