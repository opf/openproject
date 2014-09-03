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

require 'spec_helper'

describe Api::V2::VersionsController, type: :controller do
  let(:project) { FactoryGirl.create(:project) }
  let(:version) { FactoryGirl.create(:version, project: project) }
  let(:admin_user) { FactoryGirl.create(:admin) }

  shared_examples_for 'unauthorized access' do
    let(:project) { FactoryGirl.create(:project) }

    before { get action, request_params }

    it { expect(response.status).to eq(401) }
  end

  describe '#index' do
    it_behaves_like 'unauthorized access' do
      let(:action) { :index }
      let(:request_params) { { project_id: project.id, format: :xml } }
    end

    context 'with access' do
      let!(:version) { FactoryGirl.create(:version, project: project) }

      before { allow(User).to receive(:current).and_return admin_user }

      describe 'single project' do
        before { get :index, project_id: project.id, format: :xml }

        it { expect(assigns(:project)).to eq(project) }

        it { expect(assigns(:projects)).to be_nil }

        it { expect(assigns(:versions)).to include(version) }
      end

      describe 'multiple projects' do
        let(:project_2) { FactoryGirl.create(:project) }
        let!(:version_2) { FactoryGirl.create(:version, project: project_2) }

        shared_examples_for 'request with multiple projects' do
          before do
            get :index,
                project_id: projects.collect(&:id).join(','),
                format: :xml
          end

          it { expect(assigns(:project)).to be_nil }

          it { expect(assigns(:projects)).to match_array(expected_projects) }

          it { expect(assigns(:versions)).to match_array(expected_versions) }
        end

        context 'user has access to all projects' do
          it_behaves_like 'request with multiple projects' do
            let(:projects) { [project, project_2] }
            let(:expected_projects) { projects }
            let(:expected_versions) { [version, version_2] }
          end
        end

        context 'user has access only to one project' do
          let(:user) { FactoryGirl.create(:user, member_in_project: project) }

          before { allow(User).to receive(:current).and_return user }

          it_behaves_like 'request with multiple projects' do
            let(:projects) { [project, project_2] }
            let(:expected_projects) { [project] }
            let(:expected_versions) { [version] }
          end
        end
      end
    end
  end

  describe '#show' do
    let(:project) { FactoryGirl.create(:project) }
    let(:version) { FactoryGirl.create(:version, name: 'Sprint 45', project: project) }

    before do
      allow(User).to receive(:current).and_return admin_user
    end

    context 'with access' do
      it 'that does not exist should raise an error' do
        get :show, id: '0', project_id: project.id, format: :json
        expect(response.response_code).to eq(404)
      end

      it 'that exists should return the proper version' do
        get :show, id: version.id, project_id: project.id, format: :json
        expect(assigns(:version)).to eql version
      end
    end
  end
end
