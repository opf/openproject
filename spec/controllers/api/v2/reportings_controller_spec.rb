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

describe Api::V2::ReportingsController, type: :controller do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe 'index.xml' do
    describe 'w/o a given project' do
      it 'renders a 404 Not Found page' do
        get 'index', format: 'xml'

        expect(response.response_code).to eq(404)
      end
    end

    describe 'w/ an unknown project' do
      it 'renders a 404 Not Found page' do
        get 'index', params: { project_id: '4711' }, format: 'xml'

        expect(response.response_code).to eq(404)
      end
    end

    describe 'w/ a known project' do
      let(:project) { FactoryGirl.create(:project, identifier: 'test_project') }

      def fetch
        get 'index', params: { project_id: project.identifier }, format: 'xml'
      end
      let(:permission) { :view_reportings }
      it_should_behave_like 'a controller action which needs project permissions'

      describe 'w/o any reportings within the project' do
        it 'assigns an empty reportings array' do
          get 'index', params: { project_id: project.identifier }, format: 'xml'
          expect(assigns(:reportings)).to eq([])
        end

        it 'renders the index builder template' do
          get 'index', params: { project_id: project.identifier }, format: 'xml'
          expect(response).to render_template('api/v2/reportings/index')
        end
      end

      describe 'w/ 3 reportings within the project' do
        before do
          @created_reportings = [
            FactoryGirl.create(:reporting, project_id: project.id),
            FactoryGirl.create(:reporting, project_id: project.id),
            FactoryGirl.create(:reporting, reporting_to_project_id: project.id)
          ]
        end

        it 'assigns a reportings array containing all three elements' do
          get 'index', params: { project_id: project.identifier }, format: 'xml'
          expect(assigns(:reportings)).to match_array(@created_reportings)
        end

        it 'renders the index builder template' do
          get 'index', params: { project_id: project.identifier }, format: 'xml'
          expect(response).to render_template('api/v2/reportings/index')
        end

        describe 'w/ ?only=via_source' do
          it 'assigns a reportings array containg the two reportings where project.id is source' do
            get 'index',
                params: { project_id: project.identifier, only: 'via_source' },
                format: 'xml'
            expect(assigns(:reportings)).to match_array(@created_reportings[0..1])
          end
        end

        describe 'w/ ?only=via_target' do
          it 'assigns a reportings array containg the two reportings where project.id is source' do
            get 'index',
                params: { project_id: project.identifier, only: 'via_target' },
                format: 'xml'
            expect(assigns(:reportings)).to eq(@created_reportings[2..2])
          end
        end
      end
    end
  end

  describe 'show.xml' do
    describe 'w/o a valid reporting id' do
      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'show', params: { id: '4711' }, format: 'xml'

          expect(response.response_code).to eq(404)
        end
      end

      describe 'w/ an unknown project' do
        it 'renders a 404 Not Found page' do
          get 'index', params: { project_id: '4711', id: '1337' }, format: 'xml'

          expect(response.response_code).to eq(404)
        end
      end

      describe 'w/ a known project' do
        let(:project) { FactoryGirl.create(:project, identifier: 'test_project') }

        it 'raises ActiveRecord::RecordNotFound errors' do
          expect {
            get 'show', params: { project_id: project.id, id: '1337' }, format: 'xml'
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe 'w/ a valid reporting id' do
      let(:project) { FactoryGirl.create(:project, identifier: 'test_project') }
      let(:reporting) { FactoryGirl.create(:reporting, project_id: project.id) }

      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'show', params: { id: reporting.id }, format: 'xml'

          expect(response.response_code).to eq(404)
        end
      end

      describe 'w/ a known project' do
        def fetch
          get 'show', params: { project_id: project.id, id: reporting.id }, format: 'xml'
        end
        let(:permission) { :view_reportings }
        it_should_behave_like 'a controller action which needs project permissions'

        it 'assigns the reporting' do
          get 'show', params: { project_id: project.id, id: reporting.id }, format: 'xml'
          expect(assigns(:reporting)).to eq(reporting)
        end

        it 'renders the index builder template' do
          get 'index', params: { project_id: project.id, id: reporting.id }, format: 'xml'
          expect(response).to render_template('api/v2/reportings/index')
        end
      end
    end
  end
end
