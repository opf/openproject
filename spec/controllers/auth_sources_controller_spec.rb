#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe AuthSourcesController do
  let(:current_user) { create(:admin) }

  before do
    allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(false)

    allow(User).to receive(:current).and_return current_user
  end

  describe 'index' do
    before do
      get :index
    end

    it { expect(assigns(:auth_source)).to be_nil }
    it { expect(response).to have_http_status :ok }
    it { is_expected.to render_template :index }
  end

  describe 'new' do
    before do
      get :new
    end

    it { expect(assigns(:auth_source)).not_to be_nil }
    it { expect(response).to have_http_status :ok }
    it { is_expected.to render_template :new }

    it 'initializes a new AuthSource' do
      expect(assigns(:auth_source).class).to eq(AuthSource)
      expect(assigns(:auth_source)).to be_new_record
    end
  end

  describe 'create' do
    before do
      post :create, params: { auth_source: { name: 'Test' } }
    end

    it { expect(response).to have_http_status :redirect }
    it { is_expected.to redirect_to auth_sources_path }
    it { expect(flash[:notice]).to match(/success/i) }
  end

  describe 'edit' do
    before do
      @auth_source = create(:auth_source, name: 'TestEdit')
      get :edit, params: { id: @auth_source.id }
    end

    it { expect(assigns(:auth_source)).to eq @auth_source }
    it { expect(response).to have_http_status :ok }
    it { is_expected.to render_template :edit }
  end

  describe 'update' do
    before do
      @auth_source = create(:auth_source, name: 'TestEdit')
      post :update, params: { id: @auth_source.id, auth_source: { name: 'TestUpdate' } }
    end

    it { expect(response).to have_http_status :redirect }
    it { is_expected.to redirect_to auth_sources_path }
    it { expect(flash[:notice]).to match(/update/i) }
  end

  describe 'destroy' do
    before do
      @auth_source = create(:auth_source, name: 'TestEdit')
    end

    context 'without users' do
      before do
        post :destroy, params: { id: @auth_source.id }
      end

      it { expect(response).to have_http_status :redirect }
      it { is_expected.to redirect_to auth_sources_path }
      it { expect(flash[:notice]).to match(/deletion/) }
    end

    context 'with users' do
      before do
        create(:user, auth_source: @auth_source)
        post :destroy, params: { id: @auth_source.id }
      end

      it { expect(response).to have_http_status :redirect }

      it 'does not destroy the AuthSource' do
        expect(AuthSource.find(@auth_source.id)).not_to be_nil
      end
    end
  end

  context 'with password login disabled' do
    before do
      allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
    end

    it 'cannot find index' do
      get :index

      expect(response).to have_http_status :not_found
    end

    it 'cannot find new' do
      get :new

      expect(response).to have_http_status :not_found
    end

    it 'cannot find create' do
      post :create, params: { auth_source: { name: 'Test' } }

      expect(response).to have_http_status :not_found
    end

    it 'cannot find edit' do
      get :edit, params: { id: 42 }

      expect(response).to have_http_status :not_found
    end

    it 'cannot find update' do
      post :update, params: { id: 42, auth_source: { name: 'TestUpdate' } }

      expect(response).to have_http_status :not_found
    end

    it 'cannot find destroy' do
      post :destroy, params: { id: 42 }

      expect(response).to have_http_status :not_found
    end
  end
end
