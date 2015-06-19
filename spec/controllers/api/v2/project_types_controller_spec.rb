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

require File.expand_path('../../../../spec_helper', __FILE__)

describe Api::V2::ProjectTypesController, type: :controller do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe 'index.xml' do
    def fetch
      get 'index', format: 'xml'
    end
    it_should_behave_like 'a controller action with unrestricted access'

    describe 'with no project types available' do
      it 'assigns an empty project_types array' do
        get 'index', format: 'xml'
        expect(assigns(:project_types)).to eq([])
      end

      it 'renders the index builder template' do
        get 'index', format: 'xml'
        expect(response).to render_template('api/v2/project_types/index', formats: ['api'])
      end
    end

    describe 'with some project types available' do
      before do
        @created_project_types = [
          FactoryGirl.create(:project_type),
          FactoryGirl.create(:project_type),
          FactoryGirl.create(:project_type)
        ]
      end

      it 'assigns an array with all project types' do
        get 'index', format: 'xml'
        expect(assigns(:project_types)).to eq(@created_project_types)
      end

      it 'renders the index template' do
        get 'index', format: 'xml'
        expect(response).to render_template('api/v2/project_types/index', formats: ['api'])
      end
    end
  end

  describe 'show.xml' do
    describe 'with unknown project type' do
      it 'raises ActiveRecord::RecordNotFound errors' do
        expect {
          get 'show', id: '1337', format: 'xml'
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe 'with an available project type' do
      before do
        @available_project_type = FactoryGirl.create(:project_type, id: '1337')
      end

      def fetch
        get 'show', id: '1337', format: 'xml'
      end
      it_should_behave_like 'a controller action with unrestricted access'

      it 'assigns the available project type' do
        get 'show', id: '1337', format: 'xml'
        expect(assigns(:project_type)).to eq(@available_project_type)
      end

      it 'renders the show template' do
        get 'show', id: '1337', format: 'xml'
        expect(response).to render_template('api/v2/project_types/show', formats: ['api'])
      end
    end
  end
end
