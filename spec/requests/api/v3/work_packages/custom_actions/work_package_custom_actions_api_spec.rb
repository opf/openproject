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

describe 'API::V3::WorkPackages::CustomActions::CustomActionsAPI', type: :request do
  include API::V3::Utilities::PathHelper

  let(:role) do
    FactoryGirl.create(:role,
                       permissions: %i[edit_work_packages view_work_packages])
  end
  let(:project) { FactoryGirl.create(:project) }
  let(:work_package) do
    FactoryGirl.create(:work_package,
                       project: project,
                       assigned_to: user)
  end
  let(:user) do
    FactoryGirl.create(:user,
                       member_in_project: project,
                       member_through_role: role)
  end
  let(:action) do
    FactoryGirl.create(:custom_action, actions: [CustomActions::Actions::AssignedTo.new(nil)])
  end
  let(:parameters) do
    {
      lockVersion: work_package.lock_version
    }
  end

  before do
    login_as(user)
  end

  shared_context 'post request' do
    before do
      post api_v3_paths.work_package_custom_action_execute(work_package.id, action.id),
           parameters.to_json,
           'CONTENT_TYPE' => 'application/json'
    end
  end

  context 'for an existing action' do
    include_context 'post request'

    it 'is a 200 OK' do
      expect(last_response.status)
        .to eql(200)
    end

    it 'returns the altered work package' do
      expect(last_response.body)
        .to be_json_eql('WorkPackage'.to_json)
        .at_path('_type')
      expect(last_response.body)
        .to be_json_eql(nil.to_json)
        .at_path('_links/assignee/href')
      expect(last_response.body)
        .to be_json_eql(work_package.lock_version + 1)
        .at_path('lockVersion')
    end
  end

  context 'on a conflict' do
    let(:parameters) do
      {
        lockVersion: 0
      }
    end

    before do
      # bump lock version
      WorkPackage.where(id: work_package.id).update_all(lock_version: 1)
    end

    include_context 'post request'

    it_behaves_like 'update conflict'
  end

  context 'without a lock version' do
    let(:parameters) do
      {}
    end

    include_context 'post request'

    it_behaves_like 'update conflict'
  end
end
