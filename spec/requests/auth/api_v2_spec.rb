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

describe 'API v2', type: :request do
  let(:valid_password) { 'foobar!1234!foobar' }
  let(:admin) {
    FactoryGirl.create :admin,
                       login: 'admin',
                       password: valid_password,
                       password_confirmation: valid_password
  }
  let(:project) { FactoryGirl.create(:project) }

  before do
    @api_key = api_key
    allow(Setting).to receive(:login_required?).and_return true
    allow(Setting).to receive(:rest_api_enabled?).and_return true
  end

  after do
    User.current = nil # api key auth sets the current user, reset it to make test idempotent
  end

  describe 'API authentication' do
    let(:api_key) { admin.api_key }

    shared_examples_for 'API key access' do
      context 'invalid' do
        before { get "#{request_url}?key=invalid_key" }

        it { expect(response.status).to eq(401) }
      end

      context 'valid' do
        before { get "#{request_url}?key=#{api_key}" }

        it { expect(response.status).to eq(200) }
      end
    end

    shared_examples_for 'API Basic Auth access' do
      let(:used_password) { valid_password }
      let(:credentials) {
        ActionController::HttpAuthentication::Basic.encode_credentials('admin', used_password)
      }

      before do
        allow(OpenProject::Configuration).to receive(:apiv2_enable_basic_auth?).and_return(enabled)
        get request_url, headers: { 'Authorization' => credentials }
      end

      context 'when enabled' do
        let(:enabled) { true }

        context 'valid' do
          it { expect(response.status).to eq(200) }
        end

        context 'invalid' do
          let(:used_password) { 'foobar' }
          it { expect(response.status).to eq(401) }
        end
      end

      context 'when disabled' do
        let(:enabled) { false }
        it { expect(response.status).to eq(401) }
      end
    end

    describe 'for planning element types' do
      let(:request_url) { "/api/v2/projects/#{project.id}/planning_element_types.json" }

      it_behaves_like 'API key access'
      it_behaves_like 'API Basic Auth access'
    end

    describe 'for project associations' do
      let(:request_url) { "/api/v2/projects/#{project.id}/project_associations.xml" }

      it_behaves_like 'API key access'
      it_behaves_like 'API Basic Auth access'
    end

    describe "for project associations' available projects" do
      let(:request_url) { "/api/v2/projects/#{project.id}/project_associations/available_projects.xml" }

      it_behaves_like 'API key access'
      it_behaves_like 'API Basic Auth access'
    end

    describe 'for reportings' do
      let(:request_url) { "/api/v2/projects/#{project.id}/reportings.xml" }

      it_behaves_like 'API key access'
      it_behaves_like 'API Basic Auth access'
    end

    describe "for reportings' available projects" do
      let(:request_url) { "/api/v2/projects/#{project.id}/reportings/available_projects.xml" }

      it_behaves_like 'API key access'
      it_behaves_like 'API Basic Auth access'
    end
  end
end
