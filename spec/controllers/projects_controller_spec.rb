#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ProjectsController, type: :controller do
  using_shared_fixtures :admin
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

    context 'with parent project' do
      let!(:parent) { FactoryBot.create :project, name: 'Parent' }

      it 'sets the parent of the project' do
        get 'new', params: { parent_id: parent.id }
        expect(response).to be_successful
        expect(response).to render_template 'new'
        expect(assigns(:project).parent).to eq parent
      end
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

    context 'by non-admin user with add_subprojects permission' do
      render_views

      let(:parent) { FactoryBot.create :project }
      let(:add_subproject_role) do
        FactoryBot.create(:role, permissions: %i[add_subprojects view_project view_work_packages])
      end
      let(:member) do
        FactoryBot.create :user,
                          member_in_project: parent,
                          member_through_role: add_subproject_role
      end

      before do
        login_as member
      end

      it 'should accept get' do
        get :new, params: { parent_id: parent.id }
        expect(response).to be_successful
        expect(response).to render_template 'new'
        expect(response.body).to have_selector("option[selected]", text: parent.name, visible: :all)
      end
    end

    context 'with template project' do
      let!(:template) { FactoryBot.create :template_project }
      render_views

      it 'allows to select that template' do
        get :new
        expect(response).to be_successful
        expect(response).to render_template :new
        expect(response.body).to have_selector('option', text: template.name, visible: :all)
      end
    end
  end

  context 'with default modules',
          with_settings: { default_projects_modules: %w(work_package_tracking repository) } do

    it 'should create should preserve modules on validation failure' do
      expect do
        post :create,
             params: {
               project: {
                 name: 'blog',
                 identifier: '',
                 enabled_module_names: %w(work_package_tracking news)
               }
             }
      end.not_to(change { Project.count })

      expect(response).to be_successful
      project = assigns(:project)
      expect(project.enabled_module_names.sort).to eq %w(news work_package_tracking)
    end
  end

  describe '#create' do
    shared_let(:project_custom_field) { FactoryBot.create :list_project_custom_field }
    let(:selected_custom_field_value) { project_custom_field.possible_values.find_by(value: 'A') }
    shared_let(:wp_custom_field) { FactoryBot.create :string_wp_custom_field }
    shared_let(:types) { FactoryBot.create_list :type, 2 }
    shared_let(:parent) { FactoryBot.create :project }

    context 'by admin user' do
      it 'should create a new project' do
        post :create,
             params: {
               project: {
                 name: 'blog',
                 description: 'weblog',
                 identifier: 'blog',
                 public: 1,
                 custom_field_values: { project_custom_field.id => selected_custom_field_value },
                 type_ids: types.map(&:id),
                 # an issue custom field that is not for all project
                 work_package_custom_field_ids: [wp_custom_field.id],
                 enabled_module_names: ['work_package_tracking', 'news', 'repository']
               }
             }

        expect(response).to redirect_to '/projects/blog/work_packages'

        project = Project.find_by(name: 'blog')
        expect(project).to be_active
        expect(project).to be_public
        expect(project.description).to eq 'weblog'
        expect(project.parent).to eq nil
        expect(project.custom_value_for(project_custom_field.id).typed_value).to eq 'A'
        expect(project.types.map(&:id).sort).to eq types.map(&:id).sort
        expect(project.enabled_module_names.sort).to eq ['news', 'repository', 'work_package_tracking']
        expect(project.work_package_custom_fields).to contain_exactly(wp_custom_field)
      end

      it 'should create a new subproject' do
        post :create,
             params: {
               project: {
                 name: 'blog',
                 description: 'weblog',
                 identifier: 'blog',
                 public: 1,
                 parent_id: parent.id
               }
             }
        expect(response).to redirect_to '/projects/blog/work_packages'

        project = Project.find_by(name: 'blog')
        expect(project.parent).to eq parent
      end
    end

    context 'by non-admin user with add_project permission' do
      let(:non_member_user) { FactoryBot.create :user }
      # We need at least one givable role to make the user member
      let!(:role) { FactoryBot.create :role, permissions: [:view_project] }
      before do
        non_member.update_attribute :permissions, [:add_project, :view_work_packages]
        login_as non_member_user
      end

      it 'should accept create a Project' do
        post :create,
             params: {
               project: {
                 name: 'blog',
                 description: 'weblog',
                 identifier: 'blog',
                 public: 1,
                 custom_field_values: { project_custom_field.id => selected_custom_field_value },
                 type_ids: types.map(&:id),
                 enabled_module_names: ['work_package_tracking', 'news', 'repository']
               }
             }

        expect(response).to redirect_to '/projects/blog'

        project = Project.find_by(name: 'blog')
        expect(project).to be_active
        expect(project).to be_public
        expect(project.description).to eq 'weblog'
        expect(project.parent).to eq nil
        expect(project.custom_value_for(project_custom_field.id).typed_value).to eq 'A'
        expect(project.types.map(&:id).sort).to eq types.map(&:id).sort
        expect(project.enabled_module_names.sort).to eq ['news', 'repository', 'work_package_tracking']

        # User should be added as a project member
        expect(non_member_user).to be_member_of(project)
        expect(project.members.size).to eq 1
      end

      it 'should fail with parent_id' do
        expect do
          post :create,
               params: {
                 project: {
                   name: 'blog',
                   description: 'weblog',
                   identifier: 'blog',
                   public: 1,
                   custom_field_values: { project_custom_field.id => selected_custom_field_value },
                   parent_id: parent.id
                 }
               }
        end.not_to change { Project.count }

        project = assigns(:project)
        errors = assigns(:errors)

        expect(response).to be_successful
        expect(project).to be_kind_of Project
        expect(errors[:parent]).to be_present
      end
    end

    context 'by non-admin user with add_subprojects permission' do
      let(:add_subproject_role) do
        FactoryBot.create(:role, permissions: %i[add_subprojects view_project view_work_packages])
      end
      let(:member) do
        FactoryBot.create :user,
                          member_in_project: parent,
                          member_through_role: add_subproject_role
      end

      before do
        login_as member
      end

      it 'should create a project with a parent_id' do
        post :create,
             params: {
               project: {
                 name: 'blog',
                 description: 'weblog',
                 identifier: 'blog',
                 public: 1,
                 parent_id: parent.id
               }
             }
        assert_redirected_to '/projects/blog/work_packages'
        project = Project.find_by(name: 'blog')
        expect(project.parent).to eq parent
      end

      it 'should fail without parent_id' do
        expect do
          post :create,
               params: {
                 project: {
                   name: 'blog',
                   description: 'weblog',
                   identifier: 'blog',
                   public: 1
                 }
               }
        end.not_to(change { Project.count })

        project = assigns(:project)
        errors = assigns(:errors)

        expect(response).to be_successful
        expect(project).to be_kind_of Project
        expect(errors.symbols_for(:base))
          .to match_array [:error_unauthorized]
      end

      context 'with another parent' do
        let(:parent2) { FactoryBot.create :project }

        it 'should fail with unauthorized parent_id' do
          expect(member).not_to be_member_of parent2
          expect do
            post :create,
                 params: {
                   project: {
                     name: 'blog',
                     description: 'weblog',
                     identifier: 'blog',
                     public: 1,
                     custom_field_values: { '3' => '5' },
                     parent_id: 6
                   }
                 }
          end.not_to change { Project.count }

          project = assigns(:project)
          errors = assigns(:errors)

          expect(response).to be_successful
          expect(project).to be_kind_of Project
          expect(errors.symbols_for(:base))
            .to match_array [:error_unauthorized]
        end
      end
    end

    describe 'with template project' do
      let!(:template) { FactoryBot.create :template_project, identifier: 'template' }
      let(:service_double) { double('Projects::InstantiateTemplateService') }
      let(:project_params) do
        {
          name: 'blog',
          description: 'weblog',
          identifier: 'blog',
          public: '1',
          custom_field_values: { project_custom_field.id.to_s => selected_custom_field_value.id.to_s },
          type_ids: types.map { |type| type.id.to_s },
          # an issue custom field that is not for all project
          work_package_custom_field_ids: [wp_custom_field.id.to_s],
          enabled_module_names: %w[work_package_tracking news repository]
        }
      end

      it 'calls the instantiation service' do
        expect(Projects::InstantiateTemplateService)
          .to receive(:new)
                .with(user: admin, template_id: template.id.to_s)
                .and_return service_double

        expect(service_double)
          .to receive(:call) do |params|
          expect(params.to_h).to eq(project_params.stringify_keys)
          ServiceResult.new success: true, result: template
        end

        post :create,
             params: {
               from_template: template.id,
               project: project_params
             }

        expect(response).to be_redirect
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
                name: 'Test changed name',
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
end
