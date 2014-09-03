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

        shared_context 'request versions' do
          before do
            get :index,
                project_id: projects.collect(&:id).join(','),
                format: :xml
          end
        end

        shared_examples_for 'request with multiple projects' do
          include_context 'request versions'

          it { expect(assigns(:project)).to be_nil }

          it { expect(assigns(:projects)).to match_array(expected_projects) }

          it { expect(assigns(:versions)).to match_array(expected_versions) }
        end

        context 'projects are not in hierarchy' do
          let!(:version_2) { FactoryGirl.create(:version, project: project_2) }

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

        context 'projects are in hierarchy and version is shared' do
          let(:child_project) { FactoryGirl.create(:project, parent: project) }
          let(:projects) { [project, child_project] }
          let!(:shared_version) { FactoryGirl.create(:version, project: project, sharing: 'descendants') }

          it_behaves_like 'request with multiple projects' do
            let(:expected_projects) { [project, child_project] }
            let(:expected_versions) { [version, shared_version] }
          end

          describe 'shared versions' do
            include_context 'request versions'

            subject { assigns(:versions).detect{ |v| v.id == shared_version.id }.shared_with }

            it { expect(subject).to include(project.id, child_project.id) }
          end
        end
      end
    end
  end

  describe '#show' do
    it_behaves_like 'unauthorized access' do
      let(:action) { :show }
      let(:request_params) { { project_id: project.id, format: :xml } }
    end

    context 'with access' do
      before { allow(User).to receive(:current).and_return admin_user }

      describe 'invalid version' do
        before { get :show, id: '0', project_id: project.id, format: :json }

        it { expect(response.response_code).to eq(404) }
      end

      describe 'valid version' do
        before { get :show, id: version.id, project_id: project.id, format: :json }

        it { expect(assigns(:version)).to eql version }
      end

      describe 'shared version' do
        let(:child_project) { FactoryGirl.create(:project, parent: project) }
        let!(:shared_version) { FactoryGirl.create(:version, project: project, sharing: 'descendants') }

        before { get :show, id: shared_version.id, project_id: child_project.id, format: :json }

        it { expect(assigns(:version)).to eql shared_version }
      end
    end
  end
end
