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

describe CustomActionsController, type: :controller do
  let(:admin) { FactoryBot.build(:admin) }
  let(:non_admin) { FactoryBot.build(:user) }
  let(:action) { FactoryBot.build_stubbed(:custom_action) }
  let(:params) do
    { custom_action: { name: 'blubs',
                       actions: { assigned_to: 1 } } }
  end
  let(:enterprise_token) { true }

  before do
    if enterprise_token
      with_enterprise_token :custom_actions
    end
  end

  shared_examples_for 'read requires enterprise token' do
    context 'without an enterprise token' do
      let(:enterprise_token) { false }

      before do
        login_as(admin)

        call
      end

      it 'renders enterprise_token' do
        expect(response)
          .to render_template 'common/upsale'
      end
    end
  end

  shared_examples_for 'write requires enterprise token' do
    context 'without an enterprise token' do
      let(:enterprise_token) { false }

      before do
        login_as(admin)

        call
      end

      it 'renders enterprise_token' do
        expect(response.response_code)
          .to eql 403
      end
    end
  end

  shared_examples_for '403 for non admins' do
    context 'for non admins' do
      before do
        login_as(non_admin)

        call
      end

      it 'returns 403' do
        expect(response.response_code)
          .to eql 403
      end
    end
  end

  describe '#index' do
    let(:call) { get :index }
    before do
      allow(CustomAction)
        .to receive(:order_by_position)
        .and_return([action])
    end

    context 'for admins' do
      before do
        login_as(admin)

        call
      end

      it 'returns 200' do
        expect(response.response_code)
          .to eql 200
      end

      it 'renders index template' do
        expect(response)
          .to render_template('index')
      end

      it 'assigns the custom actions' do
        expect(assigns(:custom_actions))
          .to match_array [action]
      end
    end

    it_behaves_like '403 for non admins'
    it_behaves_like 'read requires enterprise token'
  end

  describe '#new' do
    let(:call) { get(:new) }

    context 'for admins' do
      before do
        login_as(admin)

        allow(CustomAction)
          .to receive(:new)
          .and_return(action)

        call
      end

      it 'returns 200' do
        expect(response.response_code)
          .to eql 200
      end

      it 'renders new template' do
        expect(response)
          .to render_template('new')
      end

      it 'assigns custom_action' do
        expect(assigns(:custom_action))
          .to eql action
      end
    end

    it_behaves_like '403 for non admins'
    it_behaves_like 'read requires enterprise token'
  end

  describe '#create' do
    let(:call) { post :create, params: params }
    let(:current_user) { admin }
    let(:service_success) { true }
    let(:permitted_params) do
      ActionController::Parameters
        .new(params)
        .require(:custom_action)
        .permit(:name)
        .merge(ActionController::Parameters.new(actions: { assigned_to: "1" }).permit!)
    end
    let!(:service) do
      service = double('create service')

      allow(CustomActions::CreateService)
        .to receive(:new)
        .with(user: admin)
        .and_return(service)

      allow(service)
        .to receive(:call)
        .with(attributes: permitted_params.to_h.merge(conditions: {}))
        .and_yield(service_result)

      service
    end
    let(:service_result) do
      ServiceResult.new(success: service_success,
                        result: action)
    end

    context 'for admins' do
      before do
        login_as(current_user)

        call
      end

      context 'on success' do
        it 'redirects to index' do
          expect(response)
            .to redirect_to(custom_actions_path)
        end
      end

      context 'on failure' do
        let(:service_success) { false }

        it 'renders new' do
          expect(response)
            .to render_template(:new)
        end

        it 'assigns custom action' do
          expect(assigns[:custom_action])
            .to eql action
        end

        it 'assigns errors' do
          expect(assigns[:errors])
            .to eql service_result.errors
        end
      end
    end

    it_behaves_like '403 for non admins'
    it_behaves_like 'write requires enterprise token'
  end

  describe '#edit' do
    let(:params) do
      { id: "42" }
    end
    let(:call) do
      get :edit, params: params
    end

    before do
      allow(CustomAction)
        .to receive(:find)
        .with(params[:id])
        .and_return(action)
    end

    context 'for admins' do
      before do
        login_as(admin)

        call
      end

      it 'returns 200' do
        expect(response.response_code)
          .to eql 200
      end

      it 'renders edit template' do
        expect(response)
          .to render_template('edit')
      end

      it 'assigns custom_action' do
        expect(assigns(:custom_action))
          .to eql action
      end
    end

    context 'for admins on invalid id' do
      before do
        allow(CustomAction)
          .to receive(:find)
          .with(params[:id])
          .and_raise(ActiveRecord::RecordNotFound)

        login_as(admin)

        call
      end

      it 'returns 404 NOT FOUND' do
        expect(response.response_code)
          .to eql 404
      end
    end

    it_behaves_like '403 for non admins'
    it_behaves_like 'read requires enterprise token'
  end

  describe '#update' do
    let(:call) { patch :update, params: params }
    let(:current_user) { admin }
    let(:service_success) { true }
    let(:permitted_params) do
      ActionController::Parameters
        .new(params)
        .require(:custom_action)
        .permit(:name)
        .merge(ActionController::Parameters.new(actions: { assigned_to: "1" }).permit!)
    end
    let(:params) do
      { custom_action: { name: 'blubs',
                         actions: { assigned_to: 1 } },
        id: "42" }
    end
    let!(:service) do
      service = double('update service')

      allow(CustomActions::UpdateService)
        .to receive(:new)
        .with(user: admin, action: action)
        .and_return(service)

      allow(service)
        .to receive(:call)
        .with(attributes: permitted_params.to_h.merge(conditions: {}))
        .and_yield(service_result)

      service
    end
    let(:service_result) do
      ServiceResult.new(success: service_success,
                        result: action)
    end

    before do
      allow(CustomAction)
        .to receive(:find)
        .with(params[:id])
        .and_return(action)
    end

    context 'for admins' do
      before do
        login_as(current_user)

        call
      end

      context 'on success' do
        it 'redirects to index' do
          expect(response)
            .to redirect_to(custom_actions_path)
        end
      end

      context 'on failure' do
        let(:service_success) { false }

        it 'rerenders edit action' do
          expect(response)
            .to render_template(:edit)
        end

        it 'assigns the action' do
          expect(assigns[:custom_action])
            .to eql(action)
        end

        it 'assigns errors' do
          expect(assigns[:errors])
            .to eql service_result.errors
        end
      end
    end

    context 'for admins on invalid id' do
      before do
        allow(CustomAction)
          .to receive(:find)
          .with(params[:id])
          .and_raise(ActiveRecord::RecordNotFound)

        login_as(current_user)

        call
      end

      it 'returns 404 NOT FOUND' do
        expect(response.response_code)
          .to eql 404
      end
    end

    it_behaves_like '403 for non admins'
    it_behaves_like 'write requires enterprise token'
  end

  describe '#destroy' do
    let(:call) { delete :destroy, params: params }
    let(:current_user) { admin }
    let(:params) do
      { id: "42" }
    end

    before do
      allow(CustomAction)
        .to receive(:find)
        .with(params[:id])
        .and_return(action)
    end

    context 'for admins' do
      before do
        expect(action)
          .to receive(:destroy)
          .and_return(true)

        login_as(current_user)

        call
      end

      it 'redirects to index' do
        expect(response)
          .to redirect_to(custom_actions_path)
      end
    end

    context 'for admins on invalid id' do
      before do
        allow(CustomAction)
          .to receive(:find)
          .with(params[:id])
          .and_raise(ActiveRecord::RecordNotFound)

        login_as(current_user)

        call
      end

      it 'returns 404 NOT FOUND' do
        expect(response.response_code)
          .to eql 404
      end
    end

    it_behaves_like '403 for non admins'
    it_behaves_like 'write requires enterprise token'
  end
end
