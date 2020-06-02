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

##
describe AccountController, 'Auth header logout', type: :controller do
  render_views

  let!(:auth_source) { DummyAuthSource.create name: "Dummy LDAP" }
  let!(:user) { FactoryBot.create :user, login: login, auth_source_id: auth_source.id }
  let(:login) { "h.wurst" }

  before do
    if sso_config
      allow(OpenProject::Configuration)
        .to receive(:auth_source_sso)
        .and_return(sso_config)
    end
  end

  describe 'logout' do
    context 'when a logout URL is present' do
      let(:sso_config) do
        {
          logout_url: 'https://example.org/foo?logout=true'
        }
      end

      context 'and the user came from auth source' do
        before do
          login_as user
          session[:user_from_auth_header] = true
          get :logout
        end

        it 'is redirected to the logout URL' do
          expect(response).to redirect_to 'https://example.org/foo?logout=true'
        end
      end

      context 'and the user did not come from auth source' do
        before do
          login_as user
          session[:user_from_auth_header] = nil
          get :logout
        end

        it 'is redirected to the home URL' do
          expect(response).to redirect_to home_url
        end
      end
    end
  end
end
