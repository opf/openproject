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

describe ::Webhooks::Outgoing::AdminController, type: :controller do
  let(:user) { FactoryBot.build_stubbed :admin }

  before do
    login_as user
  end

  context 'when not admin' do
    let(:user) { FactoryBot.build_stubbed :user }

    it 'renders 403' do
      get :index
      expect(response.status).to eq 403
    end
  end

  context 'when not logged in' do
    let(:user) { User.anonymous }

    it 'renders 403' do
      get :index
      expect(response.status).to redirect_to(signin_url(back_url: admin_outgoing_webhooks_url))
    end
  end

  describe '#index' do
    it 'renders the index page' do
      get :index
      expect(response).to be_successful
      expect(response).to render_template 'index'
    end
  end

  describe '#new' do
    it 'renders the new page' do
      get :new
      expect(response).to be_successful
      expect(assigns[:webhook]).to be_new_record
      expect(response).to render_template 'new'
    end
  end

  describe '#create' do
    let(:service) { double(::Webhooks::Outgoing::UpdateWebhookService) }
    let(:webhook_params) do
      {
        name: 'foo',
        enabled: true
      }
    end

    describe 'with invalid params' do
      it 'renders an error' do
        post :create, params: { foo: 'bar' }
        expect(response).not_to be_successful
      end
    end

    describe 'Calling the service' do
      before do
        expect(::Webhooks::Outgoing::UpdateWebhookService)
          .to receive(:new)
          .and_return service

        expect(service)
          .to receive(:call)
          .and_return(ServiceResult.new success: success)

        post :create, params: { webhook: webhook_params}
      end

      context 'when success' do
        let(:success) { true }

        it 'renders success' do
          expect(flash[:notice]).to be_present
          expect(response).to redirect_to(action: :index)
        end
      end

      context 'when not success' do
        let(:success) { false }
        it 'renders the form again' do
          expect(flash[:notice]).not_to be_present
          expect(response).to render_template 'new'
        end
      end
    end
  end

  describe '#edit' do
    context 'when found' do
      before do
        expect(::Webhooks::Webhook)
          .to receive(:find)
          .and_return(double(::Webhooks::Webhook))
      end

      it 'renders the edit page' do
        get :edit, params: { webhook_id: 'mocked' }
        expect(response).to be_successful
        expect(assigns[:webhook]).to be_present
        expect(response).to render_template 'edit'
      end
    end

    context 'when not found' do
      it 'renders 404' do
        get :edit, params: { webhook_id: '1234' }
        expect(response).not_to be_successful
        expect(response.status).to eq 404
      end
    end
  end

  describe '#update' do
    let(:service) { double(::Webhooks::Outgoing::UpdateWebhookService) }
    let(:webhook_params) do
      {
        name: 'foo',
        enabled: true
      }
    end

    describe 'when not found' do
      it 'renders an error' do
        put :update, params: { webhook_id: 'bar' }
        expect(response).not_to be_successful
        expect(response.status).to eq 404
      end
    end

    describe 'Calling the service' do
      let(:webhook) { double(::Webhooks::Webhook) }

      before do
        allow(::Webhooks::Webhook)
          .to receive(:find)
          .and_return(webhook)

        expect(::Webhooks::Outgoing::UpdateWebhookService)
          .to receive(:new)
          .and_return service

        expect(service)
          .to receive(:call)
          .and_return(ServiceResult.new success: success)

        put :update, params: { webhook_id: '1234', webhook: webhook_params}
      end

      context 'when success' do
        let(:success) { true }

        it 'renders success' do
          expect(flash[:notice]).to be_present
          expect(response).to redirect_to(action: :index)
        end
      end

      context 'when not success' do
        let(:success) { false }

        it 'renders the form again' do
          expect(flash[:notice]).not_to be_present
          expect(response).to render_template 'edit'
        end
      end
    end
  end

  describe '#destroy' do
    let(:webhook) { double(::Webhooks::Webhook) }

    context 'when found' do
      before do
        expect(::Webhooks::Webhook)
          .to receive(:find)
          .and_return(webhook)

        expect(webhook)
          .to receive(:destroy)
          .and_return(success)
      end

      context 'when delete failed' do
        let(:success) { false }

        it 'redirects to index' do
          delete :destroy, params: { webhook_id: 'mocked' }
          expect(response).to be_redirect
          expect(flash[:notice]).not_to be_present
          expect(flash[:error]).to be_present
        end
      end

      context 'when delete success' do
        let(:success) { true }
        it 'destroys the object' do
          delete :destroy, params: { webhook_id: 'mocked' }
          expect(response).to be_redirect
          expect(flash[:notice]).to be_present
        end
      end
    end
  end
end
