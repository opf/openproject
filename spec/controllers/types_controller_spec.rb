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

describe TypesController, type: :controller do

  let(:project) {
    FactoryGirl.create(:project,
                       work_package_custom_fields: [custom_field_2])
  }
  let(:custom_field_1) {
    FactoryGirl.create(:work_package_custom_field,
                       field_format: 'string',
                       is_for_all: true)
  }
  let(:custom_field_2) { FactoryGirl.create(:work_package_custom_field) }
  let(:status_0) { FactoryGirl.create(:status) }
  let(:status_1) { FactoryGirl.create(:status) }

  context 'with an unauthorized account' do
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      allow(User).to receive(:current).and_return(current_user)
    end

    describe 'GET index' do
      describe 'the access should be restricted' do
        before { get 'index' }

        it { expect(response.status).to eq(403) }
      end
    end

    describe 'GET new' do
      describe 'the access should be restricted' do
        before { get 'new' }

        it { expect(response.status).to eq(403) }
      end
    end

    describe 'GET edit' do
      describe 'the access should be restricted' do
        before { get 'edit' }

        it { expect(response.status).to eq(403) }
      end
    end

    describe 'POST create' do
      describe 'the access should be restricted' do
        before { post 'create' }

        it { expect(response.status).to eq(403) }
      end
    end

    describe 'DELETE destroy' do
      describe 'the access should be restricted' do
        before { delete 'destroy' }

        it { expect(response.status).to eq(403) }
      end
    end

    describe 'POST update' do
      describe 'the access should be restricted' do
        before { post 'update' }

        it { expect(response.status).to eq(403) }
      end
    end

    describe 'POST move' do
      describe 'the access should be restricted' do
        before { post 'move' }

        it { expect(response.status).to eq(403) }
      end
    end
  end

  context 'with an authorized account' do
    let(:current_user) { FactoryGirl.create(:admin) }

    before do
      allow(User).to receive(:current).and_return(current_user)
    end

    describe 'GET index' do
      before { get 'index' }
      it { expect(response).to be_success }
      it { expect(response).to render_template 'index' }
    end

    describe 'GET new' do
      before { get 'new' }
      it { expect(response).to be_success }
      it { expect(response).to render_template 'new' }
    end

    describe 'POST create' do
      describe 'WITH valid params' do
        let(:params) {
          { 'type' => { name: 'New type',
                        project_ids: { '1' => project.id },
                        custom_field_ids: { '1' => custom_field_1.id, '2' => custom_field_2.id }
                                    } } }

        before do
          post :create, params
        end

        it { expect(response).to be_redirect }
        it { expect(response).to redirect_to(types_path) }
      end

      describe 'WITH an empty name' do
        render_views
        let(:params) {
          { 'type' => { name: '',
                        project_ids: { '1' => project.id },
                        custom_field_ids: { '1' => custom_field_1.id, '2' => custom_field_2.id }
                                   } } }

        before do
          post :create, params
        end

        it { expect(response.status).to eq(200) }
        it 'should show an error message' do
          expect(response.body).to have_content("Name can't be blank")
        end
      end

      describe 'WITH workflow copy' do
        let!(:existing_type) { FactoryGirl.create(:type, name: 'Existing type') }
        let!(:workflow) {
          FactoryGirl.create(:workflow,
                             old_status: status_0,
                             new_status: status_1,
                             type_id: existing_type.id)
        }
        let(:params) {
          { 'type' => { name: 'New type',
                        project_ids: { '1' => project.id },
                        custom_field_ids: { '1' => custom_field_1.id, '2' => custom_field_2.id } },
            'copy_workflow_from' => existing_type.id
        } }

        before do
          post :create, params
        end

        it { expect(response).to be_redirect }
        it { expect(response).to redirect_to(types_path) }
        it 'should have the copied workflows' do
          expect(Type.find_by_name('New type').workflows.count).to eq(existing_type.workflows.count)
        end
      end
    end

    describe 'GET edit' do
      render_views
      let(:type) { FactoryGirl.create(:type, name: 'My type', is_milestone: true, projects: [project]) }

      before do
        get 'edit', id: type.id
      end

      it { expect(response).to be_success }
      it { expect(response).to render_template 'edit' }
      it { expect(response.body).to have_selector "input[@name='type[name]'][@value='My type']" }
      it { expect(response.body).to have_selector "input[@name='type[project_ids][]'][@value='#{project.id}'][@checked='checked']" }
      it { expect(response.body).to have_selector "input[@name='type[is_milestone]'][@value='1'][@checked='checked']" }
    end

    describe 'POST update' do
      let(:project2) { FactoryGirl.create(:project) }
      let(:type) { FactoryGirl.create(:type, name: 'My type', is_milestone: true, projects: [project, project2]) }

      describe 'WITH type rename' do
        let(:params) { { 'id' => type.id, 'type' => { name: 'My type renamed' } } }

        before do
          put :update, params
        end

        it { expect(response).to be_redirect }
        it { expect(response).to redirect_to(types_path) }
        it 'should be renamed' do
          expect(Type.find_by_name('My type renamed').id).to eq(type.id)
        end
      end

      describe 'WITH projects removed' do
        let(:params) { { 'id' => type.id, 'type' => { project_ids: [''] } } }

        before do
          put :update, params
        end

        it { expect(response).to be_redirect }
        it { expect(response).to redirect_to(types_path) }
        it 'should have no projects assigned' do
          expect(Type.find_by_name('My type').projects.count).to eq(0)
        end
      end
    end

    describe 'POST move' do
      let!(:type) { FactoryGirl.create(:type, name: 'My type', position: '1') }
      let!(:type2) { FactoryGirl.create(:type, name: 'My type 2', position: '2') }
      let(:params) { { 'id' => type.id, 'type' => { move_to: 'lower' } } }

      before do
        post :move, params
      end

      it { expect(response).to be_redirect }
      it { expect(response).to redirect_to(types_path) }
      it 'should have the position updated' do
        expect(Type.find_by_name('My type').position).to eq(2)
      end
    end

    describe 'DELETE destroy' do
      let(:type) { FactoryGirl.create(:type, name: 'My type') }
      let(:type2) { FactoryGirl.create(:type, name: 'My type 2', projects: [project]) }
      let(:type3) { FactoryGirl.create(:type, name: 'My type 3', is_standard: true) }

      describe 'successful detroy' do
        let(:params) { { 'id' => type.id } }

        before do
          delete :destroy, params
        end

        it { expect(response).to be_redirect }
        it { expect(response).to redirect_to(types_path) }
        it 'should have a successful destroy flash' do
          expect(flash[:notice]).to eq(I18n.t(:notice_successful_delete))
        end
        it 'should not be present in the database' do
          expect(Type.find_by_name('My type')).to eq(nil)
        end
      end

      describe 'detroy type in use should fail' do
        let(:project2) {
          FactoryGirl.create(:project,
                             work_package_custom_fields: [custom_field_2],
                             types: [type2])
        }
        let!(:work_package) {
          FactoryGirl.create(:work_package,
                             author: current_user,
                             type: type2,
                             project: project2)
        }
        let(:params) { { 'id' => type2.id } }

        before do
          delete :destroy, params
        end

        it { expect(response).to be_redirect }
        it { expect(response).to redirect_to(types_path) }
        it 'should show an error message' do
          expect(flash[:error]).to eq(I18n.t(:error_can_not_delete_type))
        end
        it 'should be present in the database' do
          expect(Type.find_by_name('My type 2').id).to eq(type2.id)
        end
      end

      describe 'destroy standard type should fail' do
        let(:params) { { 'id' => type3.id } }

        before do
          delete :destroy, params
        end

        it { expect(response).to be_redirect }
        it { expect(response).to redirect_to(types_path) }
      end
    end
  end
end
