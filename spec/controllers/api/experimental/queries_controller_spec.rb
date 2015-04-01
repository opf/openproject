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

describe Api::Experimental::QueriesController, type: :controller do
  let(:current_user) do
    FactoryGirl.create(:user, member_in_project: project,
                              member_through_role: role)
  end
  let(:project) { FactoryGirl.create(:project) }
  let(:role) do
    FactoryGirl.create(:role, permissions: [:view_work_packages,
                                            :save_queries])
  end

  before do
    allow(User).to receive(:current).and_return(current_user)
  end

  shared_context 'expects policy to be followed' do |allowed_actions|
    let(:called_with_expected_args) { [] }

    before do
      policy = double('QueryPolicy').as_null_object
      allow(QueryPolicy).to receive(:new).and_return(policy)

      expect(policy).to receive(:allowed?) do |received_query, received_action|

        if received_query.id == query.id &&
           Array(allowed_actions).include?(received_action)
          called_with_expected_args << received_action
        end

      end.at_least(1).times.and_return(true)
    end

    after do
      expect(called_with_expected_args.uniq).to match_array(Array(allowed_actions))
    end
  end

  shared_context 'expects policy to be ignored' do |ignored_action|
    before do
      policy = double('QueryPolicy').as_null_object
      allow(QueryPolicy).to receive(:new).and_return(policy)

      pending

      expect(policy).not_to receive(:allowed?).with(anything, ignored_action)
    end
  end

  describe '#available_columns' do
    context 'with no query_id parameter' do
      it 'assigns available_columns' do
        get :available_columns, format: :json
        expect(assigns(:available_columns)).not_to be_empty
        expect(assigns(:available_columns).first).to have_key('name')
        expect(assigns(:available_columns).first).to have_key('meta_data')
      end
    end

    it 'renders the available_columns template' do
      get :available_columns, format: :json
      expect(response).to render_template('api/experimental/queries/available_columns', formats: %w(api))
    end

    context 'without the necessary permissions' do
      let(:role) { FactoryGirl.create(:role, permissions: []) }

      it 'should respond with 403 to global request' do
        get :available_columns, format: :json
        expect(response.response_code).to eql(403)
      end

      it 'should respond with 403 to project scoped request' do
        get :available_columns, format: :json, project_id: project.id
        expect(response.response_code).to eql(403)
      end
    end
  end

  describe '#custom_field_filters' do
    context 'with no query_id parameter' do
      it 'assigns custom_field_filters' do
        get :available_columns, format: :json
        expect(assigns(:custom_field_filters)).to be_nil
      end
    end

    it 'renders the custom_field template' do
      get :custom_field_filters, format: :json
      expect(response).to render_template('api/experimental/queries/custom_field_filters', formats: %w(api))
    end

    context 'without the necessary permissions' do
      let(:role) { FactoryGirl.create(:role, permissions: []) }

      it 'should respond with 403 to global request' do
        get :custom_field_filters, format: :json
        expect(response.response_code).to eql(403)
      end

      it 'should respond with 403 to project scoped request' do
        get :custom_field_filters, format: :json, project_id: project.id
        expect(response.response_code).to eql(403)
      end
    end
  end

  describe '#grouped' do
    context 'within a project' do
      it 'responds with 200' do
        get :grouped, format: :json, project_id: project.id
      end

    end

    context 'without a project' do
      it 'responds with 200' do
        get :grouped, format: :json
      end
    end

    context 'without the necessary permissions' do
      let(:role) { FactoryGirl.create(:role, permissions: []) }

      it 'should respond with 403 to global request' do
        post :grouped, format: :json
        expect(response.response_code).to eql(403)
      end

      it 'should respond with 403 to project scoped request' do
        post :grouped, format: :json, project_id: project.id
        expect(response.response_code).to eql(403)
      end
    end
  end

  describe '#create' do
    context 'within a project' do
      let(:valid_params) do
        { 'c' => ['type', 'status', 'priority', 'assigned_to'],
          'f' => ['status_id'],
          'group_by' => '',
          'is_public' => 'false',
          'name' => 'sdfsdfsdf',
          'op' => { 'status_id' => 'o' },
          'sort' => 'parent:desc',
          'project_id' => project.id,
          'format' => 'json' }
      end

      it 'responds with 200' do
        post :create, valid_params
        expect(response.response_code).to eql(200)
      end
    end

    context 'without a project' do
      let(:valid_params) do
        { 'c' => ['type', 'status', 'priority', 'assigned_to'],
          'f' => ['status_id'],
          'group_by' => '',
          'is_public' => 'false',
          'name' => 'sdfsdfsdf',
          'op' => { 'status_id' => 'o' },
          'sort' => 'parent:desc',
          'format' => 'json' }
      end

      it 'responds with 200' do
        post :create, valid_params
        expect(response.response_code).to eql(200)
      end
    end

    context 'without the necessary permissions' do
      let(:role) { FactoryGirl.create(:role, permissions: []) }

      it 'should respond with 403 to global request' do
        post :create, format: :json
        expect(response.response_code).to eql(403)
      end

      it 'should respond with 403 to project scoped request' do
        post :create, format: :json, project_id: project.id
        expect(response.response_code).to eql(403)
      end
    end
  end

  describe '#update' do
    context 'within a project' do
      let(:user) { FactoryGirl.create(:user) }
      let(:query) { FactoryGirl.create(:query, project: project, user: user) }
      let(:valid_params) do
        { 'c' => ['type', 'status', 'priority', 'assigned_to'],
          'f' => ['status_id'],
          'group_by' => '',
          'is_public' => 'false',
          'name' => 'sdfsdfsdf',
          'op' => { 'status_id' => 'o' },
          'sort' => 'parent:desc',
          'query_id' => query.id,
          'id' => query.id,
          'project_id' => project.id,
          'format' => 'json' }
      end

      shared_examples_for 'valid query update' do
        before { post :update, valid_params }

        it { expect(response.response_code).to eql(200) }
      end

      describe 'query update' do
        context 'w/o public state' do
          include_context 'expects policy to be followed', :update

          it_behaves_like 'valid query update'
        end

        describe 'public state' do
          let(:role) { FactoryGirl.create(:role, permissions: [:manage_public_queries]) }
          let!(:membership) {
            FactoryGirl.create(:member,
                               user: user,
                               project: query.project,
                               role_ids: [role.id])
          }

          before { allow(User).to receive(:current).and_return(user) }

          context 'with other changes' do
            include_context 'expects policy to be followed', [:update, :publicize]

            before { valid_params['is_public'] = true.to_s }

            it_behaves_like 'valid query update'
          end

          describe 'w/o other changes' do
            let(:change_public_state_only_params) do
              { 'f' => ['status_id'],
                'is_public' => 'true',
                'name' => query.name,
                'op' => { 'status_id' => 'o' },
                'v' => { 'status_id' => [''] },
                'query_id' => query.id,
                'id' => query.id,
                'project_id' => project.id,
                'format' => 'json' }
            end

            context 'publicize' do
              let(:admin) { FactoryGirl.create(:admin) }
              let(:valid_params) { change_public_state_only_params }

              context 'allowed policy' do
                include_context 'expects policy to be followed', :publicize

                it_behaves_like 'valid query update'
              end

              context 'forbidden policy' do
                include_context 'expects policy to be ignored', :update

                it_behaves_like 'valid query update'
              end
            end

            context 'depublicize' do
              let(:query) { FactoryGirl.create(:query, project: project, is_public: true) }
              let(:valid_params) { change_public_state_only_params.merge('is_public' => 'false') }

              context 'allowed policy' do
                include_context 'expects policy to be followed', :depublicize

                it_behaves_like 'valid query update'
              end

              context 'forbidden policy' do
                include_context 'expects policy to be ignored', :update

                it_behaves_like 'valid query update'
              end
            end
          end
        end
      end
    end

    context 'without a project' do
      let(:query) { FactoryGirl.create(:query, project: nil) }

      include_context 'expects policy to be followed', :update

      let(:valid_params) do
        { 'c' => ['type', 'status', 'priority', 'assigned_to'],
          'f' => ['status_id'],
          'group_by' => '',
          'is_public' => 'false',
          'name' => 'sdfsdfsdf',
          'op' => { 'status_id' => 'o' },
          'sort' => 'parent:desc',
          'query_id' => query.id,
          'id' => query.id,
          'format' => 'json' }
      end

      it 'responds with 200' do
        post :update, valid_params
        expect(response.response_code).to eql(200)
      end
    end

    context 'without the necessary permissions' do
      let(:role) { FactoryGirl.create(:role, permissions: []) }

      it 'should respond with 403 to global request' do
        post :update, format: :json
        expect(response.response_code).to eql(403)
      end

      it 'should respond with 403 to project scoped request' do
        post :update, format: :json, project_id: project.id
        expect(response.response_code).to eql(403)
      end
    end
  end

  describe '#destroy' do

    context 'within a project' do
      let(:query) { FactoryGirl.create(:query, project: project) }

      include_context 'expects policy to be followed', :destroy

      let(:valid_params) do
        { 'c' => ['type', 'status', 'priority', 'assigned_to'],
          'f' => ['status_id'],
          'group_by' => '',
          'is_public' => 'false',
          'name' => 'sdfsdfsdf',
          'op' => { 'status_id' => 'o' },
          'sort' => 'parent:desc',
          'query_id' => query.id,
          'id' => query.id,
          'project_id' => project.id,
          'format' => 'json' }
      end

      it 'responds with 200' do
        delete :destroy, valid_params
        expect(response.response_code).to eql(200)
      end
    end

    context 'without a project' do
      let(:query) { FactoryGirl.create(:query, project: nil) }

      include_context 'expects policy to be followed', :destroy

      let(:valid_params) do
        { 'c' => ['type', 'status', 'priority', 'assigned_to'],
          'f' => ['status_id'],
          'group_by' => '',
          'is_public' => 'false',
          'name' => 'sdfsdfsdf',
          'op' => { 'status_id' => 'o' },
          'sort' => 'parent:desc',
          'query_id' => query.id,
          'id' => query.id,
          'format' => 'json' }
      end

      it 'responds with 200' do
        delete :destroy, valid_params
        expect(response.response_code).to eql(200)
      end
    end

    context 'without the necessary permissions' do
      let(:role) { FactoryGirl.create(:role, permissions: []) }

      it 'should respond with 403 to global request' do
        delete :destroy, format: :json
        expect(response.response_code).to eql(403)
      end

      it 'should respond with 403 to project scoped request' do
        delete :destroy, format: :json, project_id: project.id
        expect(response.response_code).to eql(403)
      end
    end
  end

end
