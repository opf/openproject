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

describe CustomActionsController, type: :controller do
  let(:admin) { FactoryGirl.build(:admin) }
  let(:non_admin) { FactoryGirl.build(:user) }
  let(:action) { FactoryGirl.build_stubbed(:custom_action) }
  let(:params) do
    { custom_action: { name: 'blubs',
                       actions: { assigned_to: 1 } } }
  end

  describe '#index' do
    before do
      allow(CustomAction)
        .to receive(:order_by_name)
        .and_return([action])
    end

    context 'for admins' do
      before do
        login_as(admin)

        get :index
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

    context 'for non admins' do
      before do
        login_as(non_admin)
        get :index
      end

      it 'returns 403' do
        expect(response.response_code)
          .to eql 403
      end
    end
  end

  describe '#new' do
    context 'for admins' do
      before do
        login_as(admin)

        allow(CustomAction)
          .to receive(:new)
          .and_return(action)

        get :new
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

    context 'for non admins' do
      before do
        login_as(non_admin)
        get :new
      end

      it 'returns 403' do
        expect(response.response_code)
          .to eql 403
      end
    end
  end

  describe '#create' do
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
        .with(attributes: permitted_params.to_h)
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

        post :create, params: params
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
      end
    end

    context 'for non admins' do
      before do
        login_as(non_admin)
        get :new
      end

      it 'returns 403' do
        expect(response.response_code)
          .to eql 403
      end
    end
  end

  describe '#edit' do
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
        login_as(admin)

        get :edit, params: params
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

        get :edit, params: params
      end

      it 'returns 404 NOT FOUND' do
        expect(response.response_code)
          .to eql 404
      end
    end

    context 'for non admins' do
      before do
        login_as(non_admin)
        get :edit, params: params
      end

      it 'returns 403' do
        expect(response.response_code)
          .to eql 403
      end
    end
  end

  describe '#update' do
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
        .with(attributes: permitted_params.to_h)
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

        patch :update, params: params
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
      end
    end

    context 'for admins on invalid id' do
      before do
        allow(CustomAction)
          .to receive(:find)
          .with(params[:id])
          .and_raise(ActiveRecord::RecordNotFound)

        login_as(current_user)

        patch :update, params: params
      end

      it 'returns 404 NOT FOUND' do
        expect(response.response_code)
          .to eql 404
      end
    end

    context 'for non admins' do
      before do
        login_as(non_admin)
        get :new
      end

      it 'returns 403' do
        expect(response.response_code)
          .to eql 403
      end
    end
  end
end
