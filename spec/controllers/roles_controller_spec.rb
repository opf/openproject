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

describe RolesController, type: :controller do
  let(:user) do
    FactoryBot.build_stubbed(:admin)
  end
  let(:params) do
    {
      role: {
        name: 'A role name',
        permissions: ['add_work_packages', 'edit_work_packages', 'log_time', ''],
        assignable: '0'
      },
      copy_workflow_from: '5'
    }
  end

  before do
    login_as(user)
  end

  describe '#create' do
    let(:new_role) { double('role double') }
    let(:service_call) { ServiceResult.new(success: true, result: new_role) }
    let(:create_params) do
      cp = ActionController::Parameters.new(params[:role])
                 .merge(global_role: nil, copy_workflow_from: '5')
      cp.permit!

      cp
    end
    let(:create_service) do
      service_double = double('create service')

      expect(Roles::CreateService)
        .to receive(:new)
        .with(user: user)
        .and_return(service_double)

      expect(service_double)
        .to receive(:call)
        .with(create_params)
        .and_return(service_call)
    end

    before do
      create_service

      post :create, params: params
    end

    context 'success' do
      context 'for a member role' do
        it 'redirects to roles#index' do
          expect(response)
            .to redirect_to(roles_path)
        end

        it 'has a flash message' do
          expect(flash[:notice])
            .to eql I18n.t(:notice_successful_create)
        end
      end

      context 'for a global role' do
        let(:params) do
          {
            role: {
              name: 'A role name',
              permissions: ['add_work_packages', 'edit_work_packages', 'log_time', ''],
              assignable: '0'
            },
            global_role: '1',
            copy_workflow_from: '5'
          }
        end
        let(:create_params) do
          cp = ActionController::Parameters.new(params[:role])
                 .merge(global_role: '1', copy_workflow_from: '5')
          cp.permit!

          cp
        end

        it 'redirects to roles#index' do
          expect(response)
            .to redirect_to(roles_path)
        end

        it 'has a flash message' do
          expect(flash[:notice])
            .to eql I18n.t(:notice_successful_create)
        end
      end
    end

    context 'failure' do
      let(:service_call) { ServiceResult.new(success: false, result: new_role) }

      it 'returns a 200 OK' do
        expect(response.status)
          .to eql(200)
      end

      it 'renders the new template' do
        expect(response)
          .to render_template('roles/new')
      end

      it 'has the service call assigned' do
        expect(assigns[:call])
          .to eql service_call
      end

      it 'has the role assigned' do
        expect(assigns[:role])
          .to eql new_role
      end
    end
  end

  describe '#update' do
    let(:params) do
      {
        id: role.id,
        role: {
          name: 'A role name',
          permissions: ['add_work_packages', 'edit_work_packages', 'log_time', ''],
          assignable: '0'
        }
      }
    end
    let(:role) do
      double('role double', id: 6).tap do |d|
        allow(Role)
          .to receive(:find)
          .with(d.id.to_s)
          .and_return(d)
      end
    end
    let(:service_call) { ServiceResult.new(success: true, result: role) }
    let(:update_params) do
      cp = ActionController::Parameters.new(params[:role])
      cp.permit!

      cp
    end
    let(:update_service) do
      service_double = double('update service')

      expect(Roles::UpdateService)
        .to receive(:new)
        .with(user: user, model: role)
        .and_return(service_double)

      expect(service_double)
        .to receive(:call)
        .with(update_params)
        .and_return(service_call)
    end

    before do
      update_service

      put :update, params: params
    end

    context 'success' do
      it 'redirects to roles#index' do
        expect(response)
          .to redirect_to(roles_path)
      end

      it 'has a flash message' do
        expect(flash[:notice])
          .to eql I18n.t(:notice_successful_update)
      end
    end

    context 'failure' do
      let(:service_call) { ServiceResult.new(success: false, result: role) }

      it 'returns a 200 OK' do
        expect(response.status)
          .to eql(200)
      end

      it 'renders the edit template' do
        expect(response)
          .to render_template('roles/edit')
      end

      it 'has the service call assigned' do
        expect(assigns[:call])
          .to eql service_call
      end

      it 'has the role assigned' do
        expect(assigns[:role])
          .to eql role
      end
    end
  end

  describe '#bulk_update' do
    let(:params) do
      {
        permissions: { '0' => '', '1' => ['edit_work_packages'], '3' => %w(add_work_packages delete_work_packages) }
      }
    end
    let(:role0) do
      double('role double', id: 0)
    end
    let(:role1) do
      double('role double', id: 1)
    end
    let(:role2) do
      double('role double', id: 2)
    end
    let(:role3) do
      double('role double', id: 3)
    end
    let(:roles) do
      [role0, role1, role2, role3]
    end

    let!(:roles_scope) do
      allow(Role)
        .to receive(:order)
        .and_return(roles)
    end

    let(:service_call0) { ServiceResult.new(success: true, result: role0) }
    let(:service_call1) { ServiceResult.new(success: true, result: role1) }
    let(:service_call2) { ServiceResult.new(success: true, result: role2) }
    let(:service_call3) { ServiceResult.new(success: true, result: role3) }
    let(:update_params0) do
      { permissions: [] }
    end
    let(:update_service0) do
      service_double = double('update service')

      expect(Roles::UpdateService)
        .to receive(:new)
        .with(user: user, model: role0)
        .and_return(service_double)

      expect(service_double)
        .to receive(:call)
        .with(update_params0)
        .and_return(service_call0)
    end
    let(:update_params1) do
      { permissions: params[:permissions]['1'] }
    end
    let(:update_service1) do
      service_double = double('update service')

      expect(Roles::UpdateService)
        .to receive(:new)
        .with(user: user, model: role1)
        .and_return(service_double)

      expect(service_double)
        .to receive(:call)
        .with(update_params1)
        .and_return(service_call1)
    end
    let(:update_params2) do
      { permissions: [] }
    end
    let(:update_service2) do
      service_double = double('update service')

      expect(Roles::UpdateService)
        .to receive(:new)
        .with(user: user, model: role2)
        .and_return(service_double)

      expect(service_double)
        .to receive(:call)
        .with(update_params2)
        .and_return(service_call2)
    end
    let(:update_params3) do
      { permissions: params[:permissions]['3'] }
    end
    let(:update_service3) do
      service_double = double('update service')

      expect(Roles::UpdateService)
        .to receive(:new)
        .with(user: user, model: role3)
        .and_return(service_double)

      expect(service_double)
        .to receive(:call)
        .with(update_params3)
        .and_return(service_call3)
    end

    before do
      update_service0
      update_service1
      update_service2
      update_service3

      put :bulk_update, params: params
    end

    context 'success' do
      it 'redirects to roles#index' do
        expect(response)
          .to redirect_to(roles_path)
      end

      it 'has a flash message' do
        expect(flash[:notice])
          .to eql I18n.t(:notice_successful_update)
      end
    end

    context 'failure' do
      let(:service_call2) { ServiceResult.new(success: false, result: role2) }

      it 'returns a 200 OK' do
        expect(response.status)
          .to eql(200)
      end

      it 'renders the report template' do
        expect(response)
          .to render_template('roles/report')
      end

      it 'has the service call assigned' do
        expect(assigns[:calls])
          .to match_array [service_call0, service_call1, service_call2, service_call3]
      end

      it 'has the roles assigned' do
        expect(assigns[:roles])
          .to match_array roles
      end
    end
  end
end
