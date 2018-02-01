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

describe ProjectsController, type: :controller do
  before do
    Role.delete_all
    User.delete_all
  end

  before do
    allow(@controller).to receive(:set_localization)

    @role = FactoryGirl.create(:non_member)
    @user = FactoryGirl.create(:admin)
    allow(User).to receive(:current).and_return @user

    @params = {}
  end

  describe 'show' do
    render_views

    describe 'without wiki' do
      before do
        @project = FactoryGirl.create(:project)
        @project.reload # project contains wiki by default
        @project.wiki.destroy
        @project.reload
        @params[:id] = @project.id
      end

      it 'renders show' do
        get 'show', params: @params
        expect(response).to be_success
        expect(response).to render_template 'show'
      end

      it 'renders main menu without wiki menu item' do
        get 'show', params: @params

        assert_select '#main-menu a.wiki-Wiki-menu-item', false # assert_no_select
      end
    end

    describe 'with wiki' do
      before do
        @project = FactoryGirl.create(:project)
        @project.reload # project contains wiki by default
        @params[:id] = @project.id
      end

      describe 'without custom wiki menu items' do
        it 'renders show' do
          get 'show', params: @params
          expect(response).to be_success
          expect(response).to render_template 'show'
        end

        it 'renders main menu with wiki menu item' do
          get 'show', params: @params

          assert_select '#main-menu a.wiki-wiki-menu-item', 'Wiki'
        end
      end

      describe 'with custom wiki menu item' do
        before do
          main_item = FactoryGirl.create(:wiki_menu_item, navigatable_id: @project.wiki.id, name: 'example', title: 'Example Title')
          sub_item = FactoryGirl.create(:wiki_menu_item, navigatable_id: @project.wiki.id, name: 'sub', title: 'Sub Title', parent_id: main_item.id)
        end

        it 'renders show' do
          get 'show', params: @params
          expect(response).to be_success
          expect(response).to render_template 'show'
        end

        it 'renders main menu with wiki menu item' do
          get 'show', params: @params

          assert_select '#main-menu a.wiki-example-menu-item', 'Example Title'
        end

        it 'renders main menu with sub wiki menu item' do
          get 'show', params: @params

          assert_select '#main-menu a.wiki-sub-menu-item', 'Sub Title'
        end
      end
    end

    describe 'with activated activity module' do
      before do
        @project = FactoryGirl.create(:project, enabled_module_names: %w[activity])
        @params[:id] = @project.id
      end

      it 'renders show' do
        get 'show', params: @params
        expect(response).to be_success
        expect(response).to render_template 'show'
      end

      it 'renders main menu with activity tab' do
        get 'show', params: @params
        assert_select '#main-menu a.activity-menu-item'
      end
    end

    describe 'without activated activity module' do
      before do
        @project = FactoryGirl.create(:project, enabled_module_names: %w[wiki])
        @params[:id] = @project.id
      end

      it 'renders show' do
        get 'show', params: @params
        expect(response).to be_success
        expect(response).to render_template 'show'
      end

      it 'renders main menu without activity tab' do
        get 'show', params: @params
        expect(response.body).not_to have_selector '#main-menu a.activity-menu-item'
      end
    end
  end

  describe 'new' do
    it "renders 'new'" do
      get 'new', params: @params
      expect(response).to be_success
      expect(response).to render_template 'new'
    end
  end

  describe 'index.html' do
    let(:project_a) { FactoryGirl.create(:project, name: 'Project A', is_public: false, status: true) }
    let(:project_b) { FactoryGirl.create(:project, name: 'Project B', is_public: false, status: true) }
    let(:project_c) { FactoryGirl.create(:project, name: 'Project C', is_public: true, status: true)  }
    let(:project_d) { FactoryGirl.create(:project, name: 'Project D', is_public: true, status: false) }

    let(:projects) { [project_a, project_b, project_c, project_d] }

    before do
      Role.anonymous
      projects
      login_as(user)
      get 'index'
    end

    shared_examples_for 'successful index' do
      it 'is success' do
        expect(response).to be_success
      end

      it 'renders the index template' do
        expect(response).to render_template 'index'
      end
    end

    context 'as admin' do
      let(:user) { FactoryGirl.build(:admin) }

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
      let(:user) { FactoryGirl.build(:user, member_in_project: project_b) }

      it_behaves_like 'successful index'

      it "shows (active) public projects and those in which the user is member of" do
        expect(assigns[:projects])
          .to match_array [project_b, project_c]
      end
    end
  end

  describe 'index.html' do
    let(:user) { FactoryGirl.build(:admin) }

    before do
      login_as(user)
      get 'index', format: 'atom'
    end

    it 'is 410 GONE' do
      expect(response.response_code)
        .to eql 410
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
      let(:user) { FactoryGirl.create(:admin) }
      let(:project) do
        project = FactoryGirl.build_stubbed(:project)

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
          expect(response).to redirect_to(settings_project_path(project.identifier, tab: 'types'))
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
          expect(response).to redirect_to(settings_project_path(project.identifier, tab: 'types'))
        end
      end
    end

    describe '#custom_fields' do
      let(:project) { FactoryGirl.create(:project) }
      let(:custom_field_1) { FactoryGirl.create(:work_package_custom_field) }
      let(:custom_field_2) { FactoryGirl.create(:work_package_custom_field) }

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

        it { expect(response).to redirect_to(settings_project_path(project, 'custom_fields')) }

        it 'sets flash[:notice]' do
          expect(flash[:notice]).to eql(I18n.t(:notice_successful_update))
        end
      end

      context 'with invalid project' do
        before do
          allow_any_instance_of(Project).to receive(:save).and_return(false)
          request
        end

        it { expect(response).to redirect_to(settings_project_path(project, 'custom_fields')) }

        it 'sets flash[:error]' do
          expect(flash[:error]).to include(
            "You cannot update the project's available custom fields. The project is invalid:"
          )
        end
      end
    end
  end
end
