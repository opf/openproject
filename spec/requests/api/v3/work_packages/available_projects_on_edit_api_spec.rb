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

describe 'API::V3::WorkPackages::AvailableProjectsOnEditAPI', type: :request do
  include API::V3::Utilities::PathHelper

  let(:edit_role) do
    FactoryBot.create(:role, permissions: [:edit_work_packages,
                                            :view_work_packages])
  end
  let(:move_role) do
    FactoryBot.create(:role, permissions: [:move_work_packages])
  end
  let(:project) { FactoryBot.create(:project) }
  let(:target_project) { FactoryBot.create(:project) }
  let(:work_package) { FactoryBot.create(:work_package, project: project) }
  let(:user) do
    user = FactoryBot.create(:user,
                              member_in_project: project,
                              member_through_role: edit_role)

    FactoryBot.create(:member,
                       user: user,
                       project: target_project,
                       roles: [move_role])

    user
  end

  before do
    allow(User).to receive(:current).and_return(user)
    get api_v3_paths.available_projects_on_edit(work_package.id)
  end

  context 'w/ the necessary permissions' do
    it_behaves_like 'API V3 collection response', 1, 1, 'Project'

    it 'has the project for which the move_work_packages permission exists' do
      expect(last_response.body).to be_json_eql(target_project.id).at_path('_embedded/elements/0/id')
    end
  end

  context 'w/o the edit_work_packages permission' do
    let(:edit_role) do
      FactoryBot.create(:role, permissions: [:view_work_packages])
    end

    it { expect(last_response.status).to eq(403) }
  end

  context 'w/o the view_work_packages permission' do
    let(:edit_role) do
      FactoryBot.create(:role, permissions: [:edit_work_packages])
    end

    it { expect(last_response.status).to eq(404) }
  end
end
