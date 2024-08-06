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

RSpec.describe LdapAuthSourcesController do
  let(:current_user) { create(:admin) }

  before do
    allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(false)
    allow(User).to receive(:current).and_return current_user
  end

  describe "new" do
    before do
      get :new
    end

    it { expect(assigns(:ldap_auth_source)).not_to be_nil }
    it { is_expected.to respond_with :success }
    it { is_expected.to render_template :new }

    it "initializes a new LdapAuthSource" do
      expect(assigns(:ldap_auth_source).class).to eq LdapAuthSource
      expect(assigns(:ldap_auth_source)).to be_new_record
    end
  end

  describe "index" do
    before do
      get :index
    end

    it { is_expected.to respond_with :success }
    it { is_expected.to render_template :index }
  end

  describe "create" do
    before do
      post :create, params: { ldap_auth_source: { name: "Test", host: "example.com", attr_login: "foo" } }
    end

    it { is_expected.to respond_with :redirect }
    it { is_expected.to redirect_to ldap_auth_sources_path }
    it { is_expected.to set_flash.to /success/i }
  end

  describe "edit" do
    let(:ldap) { create(:ldap_auth_source, name: "TestEdit") }

    before do
      get :edit, params: { id: ldap.id }
    end

    it { expect(assigns(:ldap_auth_source)).to eq ldap }
    it { is_expected.to respond_with :success }
    it { is_expected.to render_template :edit }
  end

  describe "update" do
    let(:ldap) { create(:ldap_auth_source, name: "TestEdit") }

    before do
      post :update, params: { id: ldap.id, ldap_auth_source: { name: "TestUpdate" } }
    end

    it { is_expected.to respond_with :redirect }
    it { is_expected.to redirect_to ldap_auth_sources_path }
    it { is_expected.to set_flash.to /update/i }
  end

  describe "destroy" do
    let(:ldap) { create(:ldap_auth_source, name: "TestEdit") }

    context "without users" do
      before do
        post :destroy, params: { id: ldap.id }
      end

      it { is_expected.to respond_with :redirect }
      it { is_expected.to redirect_to ldap_auth_sources_path }
      it { is_expected.to set_flash.to /deletion/i }
    end

    context "with users" do
      let!(:ldap) { create(:ldap_auth_source, name: "TestEdit") }
      let!(:user) { create(:user, ldap_auth_source: ldap) }

      before do
        post :destroy, params: { id: ldap.id }
      end

      it { is_expected.to respond_with :redirect }

      it "does not destroy the LdapAuthSource" do
        expect(LdapAuthSource.find(ldap.id)).not_to be_nil
      end
    end
  end

  context "with password login disabled" do
    before do
      allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
    end

    it "cannot find index" do
      get :index

      expect(response).to have_http_status :not_found
    end

    it "cannot find new" do
      get :new

      expect(response).to have_http_status :not_found
    end

    it "cannot find create" do
      post :create, params: { ldap_auth_source: { name: "Test" } }

      expect(response).to have_http_status :not_found
    end

    it "cannot find edit" do
      get :edit, params: { id: 42 }

      expect(response).to have_http_status :not_found
    end

    it "cannot find update" do
      post :update, params: { id: 42, ldap_auth_source: { name: "TestUpdate" } }

      expect(response).to have_http_status :not_found
    end

    it "cannot find destroy" do
      post :destroy, params: { id: 42 }

      expect(response).to have_http_status :not_found
    end
  end
end
