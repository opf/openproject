#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ProjectsController, type: :controller do
  shared_let(:admin) { FactoryBot.create :admin }
  let(:non_member) { FactoryBot.create :non_member }

  before do
    allow(@controller).to receive(:set_localization)

    login_as admin

    @params = {}
  end

  describe '#new' do
    it "renders 'new'" do
      get 'new', params: @params
      expect(response).to be_successful
      expect(response).to render_template 'new'
    end

    context 'by non-admin user with add_project permission' do
      let(:non_member_user) { FactoryBot.create :user }

      before do
        non_member.add_permission! :add_project
        login_as non_member_user
      end

      it 'should accept get' do
        get :new
        expect(response).to be_successful
        expect(response).to render_template 'new'
      end
    end
  end

  describe 'index.html' do
    let(:project_a) { FactoryBot.create(:project, name: 'Project A', public: false, active: true) }
    let(:project_b) { FactoryBot.create(:project, name: 'Project B', public: false, active: true) }
    let(:project_c) { FactoryBot.create(:project, name: 'Project C', public: true, active: true) }
    let(:project_d) { FactoryBot.create(:project, name: 'Project D', public: true, active: false) }

    let(:projects) { [project_a, project_b, project_c, project_d] }

    before do
      Role.anonymous
      Role.non_member

      projects
      login_as(user)
      get 'index'
    end

    shared_examples_for 'successful index' do
      it 'is success' do
        expect(response).to be_successful
      end

      it 'renders the index template' do
        expect(response).to render_template 'index'
      end
    end

    context 'as admin' do
      let(:user) { FactoryBot.build(:admin) }

      it_behaves_like 'successful index'

      it "shows all active projects" do
        expect(assigns[:projects])
          .to match_array [project_a, project_b, project_c]
      end
    end

    context 'as anonymous user' do
      let(:user) { User.anonymous }

      it_behaves_like 'successful index'

      it "shows only (active) public projects" do
        expect(assigns[:projects])
          .to match_array [project_c]
      end
    end

    context 'as user' do
      let(:user) { FactoryBot.build(:user, member_in_project: project_b) }

      it_behaves_like 'successful index'

      it "shows (active) public projects and those in which the user is member of" do
        expect(assigns[:projects])
          .to match_array [project_b, project_c]
      end
    end
  end

  describe 'settings' do
    render_views

    describe '#type' do
      let(:update_service) do
        service = double('update service')

        allow(UpdateProjectsTypesService).to receive(:new).with(project).and_return(service)

        service
      end
      let(:user) { FactoryBot.create(:admin) }
      let(:project) do
        project = FactoryBot.build_stubbed(:project)

        allow(Project).to receive(:find).and_return(project)

        project
      end

      before do
        allow(User).to receive(:current).and_return user
      end

      context 'on success' do
        before do
          expect(update_service).to receive(:call).with([1, 2, 3]).and_return true

          patch :types, params: { id: project.id, project: { 'type_ids' => ['1', '2', '3'] } }
        end

        it 'sets a flash message' do
          expect(flash[:notice]).to eql(I18n.t('notice_successful_update'))
        end

        it 'redirects to settings#types' do
          expect(response).to redirect_to(controller: '/project_settings/types', id: project, action: 'show')
        end
      end

      context 'on failure' do
        let(:error_message) { 'error message' }

        before do
          expect(update_service).to receive(:call).with([1, 2, 3]).and_return false

          allow(project).to receive_message_chain(:errors, :full_messages).and_return(error_message)

          patch :types, params: { id: project.id, project: { 'type_ids' => ['1', '2', '3'] } }
        end

        it 'sets a flash message' do
          expect(flash[:error]).to eql(error_message)
        end

        it 'redirects to settings#types' do
          expect(response).to redirect_to(controller: '/project_settings/types', id: project, action: 'show')
        end
      end
    end

    describe '#destroy' do
      let(:project) { FactoryBot.build_stubbed(:project) }
      let(:request) { delete :destroy, params: { id: project.id } }

      let(:service_result) { ::ServiceResult.new(success: success) }

      before do
        allow(Project).to receive(:find).and_return(project)
        expect_any_instance_of(::Projects::ScheduleDeletionService)
          .to receive(:call)
                .and_return service_result
      end

      context 'when service call succeeds' do
        let(:success) { true }
        it 'prints success' do
          request
          expect(response).to be_redirect
          expect(flash[:notice]).to be_present
        end
      end

      context 'when service call fails' do
        let(:success) { false }
        it 'prints fail' do
          request
          expect(response).to be_redirect
          expect(flash[:error]).to be_present
        end
      end
    end

    describe '#custom_fields' do
      let(:project) { FactoryBot.create(:project) }
      let(:custom_field_1) { FactoryBot.create(:work_package_custom_field) }
      let(:custom_field_2) { FactoryBot.create(:work_package_custom_field) }

      let(:params) do
        {
          id: project.id,
          project: {
            work_package_custom_field_ids: [custom_field_1.id, custom_field_2.id]
          }
        }
      end

      let(:request) { put :custom_fields, params: params }

      context 'with valid project' do
        before do
          request
        end

        it { expect(response).to redirect_to(controller: '/project_settings/custom_fields', id: project, action: 'show') }

        it 'sets flash[:notice]' do
          expect(flash[:notice]).to eql(I18n.t(:notice_successful_update))
        end
      end

      context 'with invalid project' do
        before do
          allow_any_instance_of(Project).to receive(:save).and_return(false)
          request
        end

        it { expect(response).to redirect_to(controller: '/project_settings/custom_fields', id: project, action: 'show') }

        it 'sets flash[:error]' do
          expect(flash[:error]).to include(
                                     "You cannot update the project's available custom fields. The project is invalid:"
                                   )
        end
      end
    end
  end

  describe 'with an existing project' do
    let(:project) { FactoryBot.create :project, identifier: 'blog' }

    context 'as manager' do
      let(:manager_role) do
        FactoryBot.create(:role, permissions: %i[view_project edit_project])
      end
      let(:manager) do
        FactoryBot.create :user,
                          member_in_project: project,
                          member_through_role: manager_role
      end

      before do
        login_as manager
      end

      it 'should update' do
        put :update,
            params: {
              id: project.id,
              project: {
                name: 'Test changed name'
              }
            }

        expect(response).to redirect_to '/projects/blog/settings/generic'
        expect(project.reload.name).to eq 'Test changed name'
      end
    end

    it 'should modules' do
      project.enabled_module_names = %w[work_package_tracking news]
      put :modules, params: {
        id: project.id,
        project: {
          enabled_module_names: %w[work_package_tracking repository]
        }
      }
      expect(response).to redirect_to '/projects/blog/settings/modules'
      expect(project.reload.enabled_module_names.sort).to eq %w[repository work_package_tracking]
    end

    it 'should get destroy info' do
      get :destroy_info, params: { id: project.id }
      expect(response).to be_successful
      expect(response).to render_template 'destroy_info'

      expect { project.reload }.not_to raise_error
    end

    it 'should archive' do
      put :archive, params: { id: project.id }

      expect(project.reload).to be_archived
    end

    it 'should unarchive' do
      project.update(active: false)
      put :unarchive, params: { id: project.id }

      expect(project.reload).to be_active
      expect(project).not_to be_archived
    end
  end

  describe '#copy' do
    let(:project) { FactoryBot.create :project, identifier: 'blog' }

    it "renders 'copy'" do
      get 'copy', params: { id: project.id }
      expect(response).to be_successful
      expect(response).to render_template 'copy'
    end

    context 'as non authorized user' do
      let(:user) { FactoryBot.build_stubbed :user }

      before do
        login_as user
      end

      it "shows an error" do
        get 'copy', params: { id: project.id }
        expect(response.status).to eq 403
      end
    end
  end
end
