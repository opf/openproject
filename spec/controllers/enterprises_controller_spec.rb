#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public EnterpriseToken version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public EnterpriseToken
# as published by the Free Software Foundation; either version 2
# of the EnterpriseToken, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public EnterpriseToken for more details.
#
# You should have received a copy of the GNU General Public EnterpriseToken
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe EnterprisesController, type: :controller do
  let(:a_token) { EnterpriseToken.new }
  let(:token_object) do
    token = OpenProject::Token.new
    token.subscriber = 'Foobar'
    token.mail = 'foo@example.org'
    token.starts_at = Date.today
    token.expires_at = nil

    token
  end

  before do
    login_as user
    allow(a_token).to receive(:token_object).and_return(token_object)
  end

  context 'with admin' do
    let(:user) { FactoryGirl.build(:admin) }

    describe '#show' do
      render_views

      context 'when token exists' do
        before do
          allow(EnterpriseToken).to receive(:current).and_return(a_token)
          get :show
        end

        it 'renders the overview' do
          expect(response).to be_success
          expect(response).to render_template 'show'
          expect(response).to render_template partial: 'enterprises/_current'
          expect(response).to render_template partial: 'enterprises/_form'
        end
      end

      context 'when no token exists' do
        before do
          allow(EnterpriseToken).to receive(:current).and_return(nil)
          get :show
        end

        it 'still renders #show with form' do
          expect(response).not_to render_template partial: 'enterprises/_current'
          expect(response.body).to have_selector '.upsale-notification'
        end
      end
    end

    describe '#create' do
      let(:params) do
        {
          enterprise_token: { encoded_token: 'foo' }
        }
      end

      before do
        allow(EnterpriseToken).to receive(:current).and_return(nil)
        allow(EnterpriseToken).to receive(:new).and_return(a_token)
        expect(a_token).to receive(:encoded_token=).with('foo')
        expect(a_token).to receive(:save).and_return(valid)

        post :create, params: params
      end

      context 'valid token input' do
        let(:valid) { true }

        it 'redirects to index' do
          expect(controller).to set_flash[:notice].to I18n.t(:notice_successful_update)
          expect(response).to redirect_to action: :show
        end
      end

      context 'invalid token input' do
        let(:valid) { false }

        it 'renders with error' do
          expect(response).not_to be_redirect
          expect(response).to render_template 'enterprises/show'
        end
      end
    end

    describe '#destroy' do
      context 'when a token exists' do
        before do
          expect(EnterpriseToken).to receive(:current).and_return(a_token)
          expect(a_token).to receive(:destroy)

          delete :destroy
        end

        it 'redirects to show' do
          expect(controller).to set_flash[:notice].to I18n.t(:notice_successful_delete)
          expect(response).to redirect_to action: :show
        end
      end

      context 'when no token exists' do
        before do
          expect(EnterpriseToken).to receive(:current).and_return(nil)
          delete :destroy
        end

        it 'renders 404' do
          expect(response.status).to eq(404)
        end
      end
    end
  end

  context 'regular user' do
    let(:user) { FactoryGirl.build(:user) }

    before do
      get :show
    end

    it 'is forbidden' do
      expect(response.status).to eq 403
    end
  end
end
