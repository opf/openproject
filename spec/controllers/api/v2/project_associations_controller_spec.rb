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

describe Api::V2::ProjectAssociationsController, type: :controller do
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
        get 'index', params: { project_id: project.id }, format: 'xml'
      end
      let(:permission) { :view_project_associations }

      it_should_behave_like 'a controller action which needs project permissions'

      describe 'w/ the current user being a member' do
        describe 'w/o any project_associations within the project' do
          it 'assigns an empty project_associations array' do
            get 'index', params: { project_id: project.id }, format: 'xml'
            expect(assigns(:project_associations)).to eq([])
          end

          it 'renders the index builder template' do
            get 'index', params: { project_id: project.id }, format: 'xml'
            expect(response).to render_template('project_associations/index')
          end
        end

        describe 'w/ 3 project_associations within the project' do
          before do
            @created_project_associations = [
              FactoryGirl.create(:project_association, project_a_id: project.id,
                                                       project_b_id: FactoryGirl.create(:public_project).id),
              FactoryGirl.create(:project_association, project_a_id: project.id,
                                                       project_b_id: FactoryGirl.create(:public_project).id),
              FactoryGirl.create(:project_association, project_b_id: project.id,
                                                       project_a_id: FactoryGirl.create(:public_project).id)
            ]
          end

          it 'assigns a project_associations array containing all three elements' do
            get 'index', params: { project_id: project.id }, format: 'xml'
            expect(assigns(:project_associations)).to eq(@created_project_associations)
          end

          it 'renders the index builder template' do
            get 'index', params: { project_id: project.id }, format: 'xml'
            expect(response).to render_template('project_associations/index')
          end
        end
      end
    end
  end

  describe 'show.xml' do
    describe 'w/o a valid project_association id' do
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

        describe 'w/ the current user being a member' do
          it 'raises ActiveRecord::RecordNotFound errors' do
            expect {
              get 'show', params: { project_id: project.id, id: '1337' }, format: 'xml'
            }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    describe 'w/ a valid project_association id' do
      let(:project) { FactoryGirl.create(:project, identifier: 'test_project') }
      let(:project_association) { FactoryGirl.create(:project_association, project_a_id: project.id) }

      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'show', params: { id: project_association.id }, format: 'xml'

          expect(response.response_code).to eq(404)
        end
      end

      describe 'w/ a known project' do
        def fetch
          get 'show', params: { project_id: project.id, id: project_association.id }, format: 'xml'
        end
        let(:permission) { :view_project_associations }

        it_should_behave_like 'a controller action which needs project permissions'

        describe 'w/ the current user being a member' do
          it 'assigns the project_association' do
            get 'show',
                params: { project_id: project.id, id: project_association.id },
                format: 'xml'
            expect(assigns(:project_association)).to eq(project_association)
          end

          it 'renders the index builder template' do
            get 'index',
                params: { project_id: project.id, id: project_association.id },
                format: 'xml'
            expect(response).to render_template('project_associations/index')
          end
        end
      end
    end
  end
end
