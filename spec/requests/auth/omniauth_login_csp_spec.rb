# frozen_string_literal: true

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

RSpec.describe "CSP form-action for OmniAuth SSO", type: :rails_request do
  include CspHelper

  def form_action_sources
    parse_csp(response.headers["Content-Security-Policy"])["form-action"]
  end

  let!(:saml_provider) { create(:saml_provider) }

  it "does not append IdP hosts on the login page" do
    get signin_path

    expect(form_action_sources).not_to include("https://example.com/")
  end

  it "does not append IdP hosts on other HTML pages" do
    get "/"

    expect(form_action_sources).not_to include("https://example.com/")
  end

  context "with a SAML provider", with_ee: %i[sso_auth_providers] do
    it "allows the IdP origin only on the auto-submit form" do
      get omniauth_login_path(saml_provider.slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(action="/auth/#{saml_provider.slug}"))
      expect(response.body).to include('data-controller="omniauth-direct-login"')
      expect(form_action_sources).to include("https://example.com/")
    end
  end

  context "with an OpenID Connect provider", with_ee: %i[sso_auth_providers] do
    let!(:oidc_provider) { create(:oidc_provider) }

    it "allows the authorization endpoint origin on the auto-submit form" do
      get omniauth_login_path(oidc_provider.slug)

      expect(form_action_sources).to include("https://keycloak.local/")
    end
  end

  context "with direct login",
          with_ee: %i[sso_auth_providers],
          with_settings: { omniauth_direct_login_provider: "saml-csp" } do
    let!(:saml_provider) { create(:saml_provider, slug: "saml-csp") }

    it "redirects from /login to the auto-submit form that allows the IdP origin" do
      get signin_path

      expect(response).to redirect_to omniauth_login_path("saml-csp")

      follow_redirect!

      expect(response.body).to include('data-controller="omniauth-direct-login"')
      expect(form_action_sources).to include("https://example.com/")
    end
  end

  it "returns 404 for an unknown provider" do
    get omniauth_login_path("unknown-provider")

    expect(response).to have_http_status(:not_found)
  end
end
