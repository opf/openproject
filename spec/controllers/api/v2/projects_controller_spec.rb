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

describe Api::V2::ProjectsController, type: :controller do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe 'w/o project_type scope' do
    describe 'index.xml' do
      describe 'with no project available' do
        it 'assigns an empty projects array' do
          get 'index', format: 'xml'
          expect(assigns(:projects)).to eq([])
        end

        it 'renders the index template' do
          get 'index', format: 'xml'
          expect(response).to render_template('api/v2/projects/index', formats: ['api'])
        end
      end

      describe 'with 3 projects available' do
        let(:current_user) { FactoryGirl.create(:user) }

        before do
          @visible_projects = [
            FactoryGirl.create(:project, is_public: false),
            FactoryGirl.create(:project, is_public: false)
          ].each do |project|
            FactoryGirl.create(:member,
                               project: project,
                               principal: current_user,
                               roles: [FactoryGirl.create(:role)])
          end
          @visible_projects << FactoryGirl.create(:project, is_public: true)

          @invisible_projects = [
            FactoryGirl.create(:project, is_public: false),
            FactoryGirl.create(:project, is_public: true,
                                         status: Project::STATUS_ARCHIVED)
          ]
        end

        it 'assigns an array with all of projects' do
          get 'index', format: 'xml'
          expect(assigns(:projects).map(&:identifier)).to eq(@visible_projects.map(&:identifier))
        end

        it 'renders the index template' do
          get 'index', format: 'xml'
          expect(response).to render_template('api/v2/projects/index', formats: ['api'])
        end
      end
    end

    describe 'show.xml' do
      describe 'public project' do
        let(:project) { FactoryGirl.create(:project, is_public: true) }
        def fetch
          get 'show', id: project.identifier, format: 'xml'
        end
        it_should_behave_like 'a controller action with unrestricted access'
      end

      describe 'private project' do
        before { $debug = true  }
        after  { $debug = false }

        let(:project) { FactoryGirl.create(:project, is_public: false) }
        def fetch
          get 'show', id: project.identifier, format: 'xml'
        end
        it_should_behave_like 'a controller action which needs project permissions'
      end

      describe 'with unknown project' do
        it 'raises ActiveRecord::RecordNotFound errors' do
          expect {
            get 'show', id: 'unknown_project', format: 'xml'
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      describe 'with an available project' do
        let(:project) { FactoryGirl.create(:project, is_public: true) }

        it 'assigns the available project' do
          get 'show', id: project.identifier, format: 'xml'
          expect(assigns(:project)).to eq(project)
        end

        it 'renders the show template' do
          get 'show', id: project.identifier, format: 'xml'
          expect(response).to render_template('api/v2/projects/show', formats: ['api'])
        end
      end
    end
  end
end
