#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe Api::Experimental::QueriesController, :type => :controller do
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

  describe '#available_columns' do
    context 'with no query_id parameter' do
      it 'assigns available_columns' do
        get :available_columns, format: :xml
        expect(assigns(:available_columns)).not_to be_empty
        expect(assigns(:available_columns).first).to have_key('name')
        expect(assigns(:available_columns).first).to have_key('meta_data')
      end
    end

    it 'renders the available_columns template' do
      get :available_columns, format: :xml
      expect(response).to render_template('api/experimental/queries/available_columns', formats: %w(api))
    end

    context 'without the necessary permissions' do
      let(:role) { FactoryGirl.create(:role, permissions: []) }

      it 'should respond with 403 to global request' do
        get :available_columns, format: :xml
        expect(response.response_code).to eql(403)
      end

      it 'should respond with 403 to project scoped request' do
        get :available_columns, format: :xml, project_id: project.id
        expect(response.response_code).to eql(403)
      end
    end
  end

  describe '#custom_field_filters' do
    context 'with no query_id parameter' do
      it 'assigns custom_field_filters' do
        get :available_columns, format: :xml
        expect(assigns(:custom_field_filters)).to be_nil
      end
    end

    it 'renders the custom_field template' do
      get :custom_field_filters, format: :xml
      expect(response).to render_template('api/experimental/queries/custom_field_filters', formats: %w(api))
    end

    context 'without the necessary permissions' do
      let(:role) { FactoryGirl.create(:role, permissions: []) }

      it 'should respond with 403 to global request' do
        get :custom_field_filters, format: :xml
        expect(response.response_code).to eql(403)
      end

      it 'should respond with 403 to project scoped request' do
        get :custom_field_filters, format: :xml, project_id: project.id
        expect(response.response_code).to eql(403)
      end
    end
  end

  describe '#grouped' do
    context 'within a project' do
      it 'responds with 200' do
        get :grouped, format: :xml, project_id: project.id
      end

    end

    context 'without a project' do
      it 'responds with 200' do
        get :grouped, format: :xml
      end
    end

    context 'without the necessary permissions' do
      let(:role) { FactoryGirl.create(:role, permissions: []) }

      it 'should respond with 403 to global request' do
        post :grouped, format: :xml
        expect(response.response_code).to eql(403)
      end

      it 'should respond with 403 to project scoped request' do
        post :grouped, format: :xml, project_id: project.id
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
          'format' => 'xml' }
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
          'format' => 'xml' }
      end

      it 'responds with 200' do
        post :create, valid_params
        expect(response.response_code).to eql(200)
      end
    end

    context 'without the necessary permissions' do
      let(:role) { FactoryGirl.create(:role, permissions: []) }

      it 'should respond with 403 to global request' do
        post :create, format: :xml
        expect(response.response_code).to eql(403)
      end

      it 'should respond with 403 to project scoped request' do
        post :create, format: :xml, project_id: project.id
        expect(response.response_code).to eql(403)
      end
    end
  end

  describe '#update' do
    context 'within a project' do
      let(:query) { FactoryGirl.create(:query, project: project) }

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
          'format' => 'xml' }
      end

      it 'responds with 200' do
        post :update, valid_params
        expect(response.response_code).to eql(200)
      end
    end

    context 'without a project' do
      let(:query) { FactoryGirl.create(:query, project: nil) }

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
          'format' => 'xml' }
      end

      it 'responds with 200' do
        post :update, valid_params
        expect(response.response_code).to eql(200)
      end
    end

    context 'without the necessary permissions' do
      let(:role) { FactoryGirl.create(:role, permissions: []) }

      it 'should respond with 403 to global request' do
        post :update, format: :xml
        expect(response.response_code).to eql(403)
      end

      it 'should respond with 403 to project scoped request' do
        post :update, format: :xml, project_id: project.id
        expect(response.response_code).to eql(403)
      end
    end
  end

  describe '#destroy' do
    context 'within a project' do
      let(:query) { FactoryGirl.create(:query, project: project) }

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
          'format' => 'xml' }
      end

      it 'responds with 200' do
        delete :destroy, valid_params
        expect(response.response_code).to eql(200)
      end
    end

    context 'without a project' do
      let(:query) { FactoryGirl.create(:query, project: nil) }

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
          'format' => 'xml' }
      end

      it 'responds with 200' do
        delete :destroy, valid_params
        expect(response.response_code).to eql(200)
      end
    end

    context 'without the necessary permissions' do
      let(:role) { FactoryGirl.create(:role, permissions: []) }

      it 'should respond with 403 to global request' do
        delete :destroy, format: :xml
        expect(response.response_code).to eql(403)
      end

      it 'should respond with 403 to project scoped request' do
        delete :destroy, format: :xml, project_id: project.id
        expect(response.response_code).to eql(403)
      end
    end
  end

end
