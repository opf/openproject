#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"
require "work_package"

RSpec.describe OAuth::ApplicationsController do
  let(:user) { build_stubbed(:admin) }
  let(:application_stub) { build_stubbed(:oauth_application, id: 1, secret: "foo") }

  before do
    login_as user
  end

  context "not logged as admin" do
    let(:user) { build_stubbed(:user) }

    it "does not grant access" do
      get :index
      expect(response.response_code).to eq 403

      get :new
      expect(response.response_code).to eq 403

      get :edit, params: { id: 1 }
      expect(response.response_code).to eq 403

      post :create
      expect(response.response_code).to eq 403

      put :update, params: { id: 1 }
      expect(response.response_code).to eq 403

      delete :destroy, params: { id: 1 }
      expect(response.response_code).to eq 403
    end
  end

  describe "#new" do
    it do
      get :new
      expect(response.status).to be 200
      expect(response).to render_template :new
    end
  end

  describe "#edit" do
    before do
      allow(Doorkeeper::Application)
        .to receive(:find)
        .with("1")
        .and_return(application_stub)
    end

    it do
      get :edit, params: { id: 1, application: { name: "foo" } }
      expect(response.status).to be 200
      expect(response).to render_template :edit
    end
  end

  describe "#create" do
    before do
      allow(Doorkeeper::Application)
        .to receive(:new)
        .and_return(application_stub)
      expect(application_stub).to receive(:attributes=)
      expect(application_stub).to receive(:save).and_return(true)
      expect(application_stub).to receive(:plaintext_secret).and_return("secret!")
    end

    it do
      post :create, params: { application: { name: "foo" } }
      expect(response).to redirect_to action: :show, id: application_stub.id
    end
  end

  describe "#update" do
    before do
      allow(Doorkeeper::Application)
        .to receive(:find)
        .with("1")
        .and_return(application_stub)
      expect(application_stub).to receive(:attributes=)
      expect(application_stub).to receive(:save).and_return(true)
    end

    it do
      patch :update, params: { id: 1, application: { name: "foo" } }
      expect(response).to redirect_to action: :index
    end
  end

  describe "#destroy" do
    before do
      allow(Doorkeeper::Application)
        .to receive(:find)
        .with("1")
        .and_return(application_stub)
      expect(application_stub).to receive(:destroy).and_return(true)
    end

    it do
      delete :destroy, params: { id: 1 }
      expect(flash[:notice]).to be_present
      expect(response).to redirect_to action: :index
    end
  end
end
