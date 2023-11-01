#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe AuthSourceSSO, :skip_2fa_stage, # Prevent redirects to 2FA stage
               type: :rails_request do
  let(:sso_config) do
    {
      header: "X-Remote-User",
      optional: true
    }
  end

  before do
    allow(OpenProject::Configuration)
      .to receive(:auth_source_sso)
            .and_return(sso_config)
  end

  describe 'with an existing LDAP user' do
    let(:ldap_auth_source) { create(:ldap_auth_source) }
    let(:user) { create(:user, login: 'bob', ldap_auth_source:) }

    it 'redirects the user to that URL' do
      get '/projects?foo=bar', headers: { 'X-Remote-User' => user.login }
      expect(response).to redirect_to '/projects?foo=bar'
    end
  end

  describe 'with an actual LDAP connection' do
    include_context 'with temporary LDAP'

    context 'when LDAP is onthefly_register' do
      let(:onthefly_register) { true }
    end

    context 'when LDAP is not onthefly_register' do
      let(:onthefly_register) { false }

      it 'returns an error when the user does not exist' do
        get '/projects', headers: { 'X-Remote-User' => 'nonexistent' }

        expect(response).to redirect_to '/sso'
        expect(session[:auth_source_sso_failure]).to be_present
      end
    end
  end
end
