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

describe Api::V2::PlanningElementTypesController, type: :controller do
  let (:admin) { FactoryGirl.create(:admin) }
  let(:project) { FactoryGirl.create(:project, is_public: false, no_types: true) }
  let(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
  let(:non_admin_user) do
    FactoryGirl.create(:user, member_in_project: project,
                              member_through_role: role)
  end

  before do
    allow(User).to receive(:current).and_return current_user
  end

  def enable_type(project, type)
    project.types << type
  end

  describe 'with project scope' do
    describe 'index.xml' do
      let(:current_user) { non_admin_user }
      let(:permission) { :view_work_packages }

      def fetch
        get 'index', params: { project_id: project.identifier }, format: 'xml'
      end
      it_should_behave_like 'a controller action which needs project permissions'

      describe 'with unknown project' do
        it 'returns 404' do
          get 'index', params: { project_id: 'blah' }, format: 'xml'

          expect(response.response_code).to eql 404
        end
      end

      describe 'with only the standard type available' do
        it 'assigns an type array including the standard type' do
          get 'index', params: { project_id: project.identifier }, format: 'xml'
          expect(assigns(:types)).to eq(project.types)
        end

        it 'renders the index builder template' do
          get 'index', params: { project_id: project.identifier }, format: 'xml'
          expect(response).to render_template('planning_element_types/index')
        end
      end

      describe 'with 3 planning element types available' do
        before do
          @created_planning_element_types = [
            FactoryGirl.create(:type),
            FactoryGirl.create(:type),
            FactoryGirl.create(:type)
          ]

          @created_planning_element_types.each do |type|
            enable_type(project, type)
          end

          @all_types = Array.new
          @all_types.concat @created_planning_element_types
          @all_types.concat ::Type.where(is_standard: true)

          # Creating one PlanningElemenType which is not assigned to any
          # Project and should therefore not show up in projects with a project
          # type
          FactoryGirl.create(:type)
        end

        it 'assigns an array with all planning element types' do
          get 'index', params: { project_id: project.identifier }, format: 'xml'
          expect(assigns(:types).to_set).to eq(@all_types.to_set)
        end

        it 'renders the index template' do
          get 'index', params: { project_id: project.identifier }, format: 'xml'
          expect(response).to render_template('planning_element_types/index')
        end
      end
    end

    describe 'show.xml' do
      let(:current_user) { non_admin_user }
      let(:permission) { :view_work_packages }

      def fetch
        @available_type = FactoryGirl.create(:type, id: '1337')
        enable_type(project, @available_type)

        get 'show', params: { project_id: project.identifier, id: '1337' }, format: 'xml'
      end
      it_should_behave_like 'a controller action which needs project permissions'

      describe 'with unknown project' do
        it 'returns 404' do
          get 'show', params: { project_id: 'blah', id: '1337' }, format: 'xml'

          expect(response.response_code).to eql 404
        end
      end

      describe 'with unknown planning element type' do
        it 'returns 404' do
          get 'show', params: { project_id: project.identifier, id: '1337' }, format: 'xml'

          expect(response.response_code).to eql 404
        end
      end

      describe 'with an planning element type, which is not enabled in the project' do
        before do
          FactoryGirl.create(:type, id: '1337')
        end

        it 'returns 404' do
          get 'show', params: { project_id: project.identifier, id: '1337' }, format: 'xml'

          expect(response.response_code).to eql 404
        end
      end

      describe 'with an available planning element type' do
        before do
          @available_planning_element_type = FactoryGirl.create(:type,
                                                                id: '1337')

          enable_type(project, @available_planning_element_type)
        end

        it 'assigns the available planning element type' do
          get 'show', params: { project_id: project.identifier, id: '1337' }, format: 'xml'
          expect(assigns(:type)).to eq(@available_planning_element_type)
        end

        it 'renders the show template' do
          get 'show', params: { project_id: project.identifier, id: '1337' }, format: 'xml'
          expect(response).to render_template('planning_element_types/show')
        end
      end
    end
  end

  describe 'without project scope' do
    describe 'index.xml' do
      let(:current_user) { non_admin_user }
      let(:permission) { :view_work_packages }

      def fetch
        get 'index', format: 'xml'
      end
      it_should_behave_like 'a controller action which needs project permissions'

      describe 'with no planning element types available' do
        it 'assigns an empty planning_element_types array' do
          get 'index', format: 'xml'
          expect(assigns(:types)).to eq([])
        end

        it 'renders the index builder template' do
          get 'index', format: 'xml'
          expect(response).to render_template('planning_element_types/index')
        end
      end

      describe 'with 3 planning element types available' do
        before do
          @created_planning_element_types = [
            FactoryGirl.create(:type),
            FactoryGirl.create(:type),
            FactoryGirl.create(:type)
          ]
        end

        it 'assigns an array with all planning element types' do
          get 'index', format: 'xml'
          expect(assigns(:types).to_set).to eq(@created_planning_element_types.to_set)
        end

        it 'renders the index template' do
          get 'index', format: 'xml'
          expect(response).to render_template('planning_element_types/index')
        end
      end
    end

    describe 'show.xml' do
      let(:current_user) { non_admin_user }
      let(:permission) { :view_work_packages }

      describe 'with unknown planning element type' do
        it 'returns 404' do
          get 'show', params: { id: '1337' }, format: 'xml'

          expect(response.response_code).to eql 404
        end
      end

      describe 'with an available planning element type' do
        before do
          @available_planning_element_type = FactoryGirl.create(:type, id: '1337')
        end

        def fetch
          get 'show', params: { id: '1337' }, format: 'xml'
        end
        it_should_behave_like 'a controller action which needs project permissions'

        it 'assigns the available planning element type' do
          get 'show', params: { id: '1337' }, format: 'xml'
          expect(assigns(:type)).to eq(@available_planning_element_type)
        end

        it 'renders the show template' do
          get 'show', params: { id: '1337' }, format: 'xml'
          expect(response).to render_template('planning_element_types/show')
        end
      end
    end
  end
end
