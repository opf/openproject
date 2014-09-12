#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

require File.expand_path('../../../../spec_helper', __FILE__)

describe Api::Experimental::VersionsController, :type => :controller do
  let(:current_user) do
    FactoryGirl.create(:user, member_in_project: project,
                              member_through_role: role)
  end
  let(:project) { FactoryGirl.create(:project) }
  let(:role)    { FactoryGirl.create(:role, permissions: [:view_work_packages]) }

  before do
    allow(User).to receive(:current).and_return(current_user)
    allow(Project).to receive(:find).and_return(project)
  end

  describe '#index' do
    context 'with no versions available' do
      it 'assigns an empty versions array' do
        get 'index', format: 'json', project_id: 1
        expect(assigns(:versions)).to eq []
      end

      it 'renders the index template' do
        get 'index', format: 'json', project_id: 1
        expect(response).to render_template('api/experimental/versions/index', formats: ['api'])
      end
    end

    context 'with versions available' do
      before do
        project.stub_chain(:shared_versions, :all).and_return(FactoryGirl.build_list(:version, 2))
      end

      it 'assigns an array with 2 versions' do
        get 'index', format: 'json', project_id: 1
        expect(assigns(:versions).size).to eq 2
      end
    end

    context 'when lacking the necessary permissions' do
      let(:role)         { FactoryGirl.create(:role, permissions: []) }

      it 'should respond with 403' do
        get 'index', format: 'json', project_id: 1
        expect(response.response_code).to eql(403)
      end
    end
  end
end
