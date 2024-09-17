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
require "rack/test"

RSpec.describe "OpenID Google provider callback", with_ee: %i[openid_providers] do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:auth_hash) do
    { "state" => "623960f1b4f1020941387659f022497f536ad3c95fa7e53b0f03bdbf36debd59f76320801ea2723df520",
      "code" => "4/0AVHEtk6HMPLH08Uw8OVoSaAbd2oTi7Z6wOlBsMQ99Yj3qgKhhyKAxUQBvQ2MZuRzvueOgQ",
      "scope" => "email profile https://www.googleapis.com/auth/userinfo.email openid https://www.googleapis.com/auth/userinfo.profile",
      "authuser" => "0",
      "prompt" => "none" }
  end
  let(:uri) do
    uri = URI("/auth/google/callback")
    uri.query = URI.encode_www_form([["code", auth_hash["code"]],
                                     ["state", auth_hash["state"]],
                                     ["scope", auth_hash["scope"]],
                                     ["authuser", auth_hash["authuser"]],
                                     ["prompt", auth_hash["prompt"]]])
    uri
  end

  before do
    # enable self registration for Google which is limited by default
    expect(OpenProject::Plugins::AuthPlugin)
      .to receive(:limit_self_registration?)
      .with(provider: "google")
      .twice
      .and_return false

    stub_request(:post, "https://accounts.google.com/o/oauth2/token").to_return(
      status: 200,
      body: {
        "access_token" =>
        "ya29.a0Ael9sCPGoZQiKuMHHVKiaiWV9NatII8T7ZY6XiwTcY-VtvSnmPH53BXDoWGU7OpFY7ctZjY0Qf-Cd_5HHULGoF_m-3WEgMvuO7F11nbYI7qoe95enqneFgDh__vvTxGRAGPpl_Xf7qbXVznh35-DHuvhyPAZmMwaCgYKAQISARASFQF4udJhMeehVtS01I8wd8HL6ReQDw0166",
        "expires_in" => 3594,
        "scope" =>
        "https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile openid",
        "token_type" => "Bearer",
        "id_token" =>
        "eyJhbGciOiJSUzI1NiIsImtpZCI6IjFhYWU4ZDdjOTIwNThiNWVlYTQ1Njg5NWJmODkwODQ1NzFlMzA2ZjMiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJhY2NvdW50cy5nb29nbGUuY29tIiwiYXpwIjoiNDI3NzUwNzQ4MTg2LWQ4OGozamNlYmN2bGlxMmd0a3RiZm1oc2lhNjYxZDU4LmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwiYXVkIjoiNDI3NzUwNzQ4MTg2LWQ4OGozamNlYmN2bGlxMmd0a3RiZm1oc2lhNjYxZDU4LmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwic3ViIjoiMTA3NDAzNTExMDM3OTIxMzU1MzA3IiwiZW1haWwiOiJiYTFhc2hwYXNoQGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJhdF9oYXNoIjoiVFBtc0ZHRng4cjdrb3RiZkJud0xVdyIsImlhdCI6MTY4MDYxMjE5NCwiZXhwIjoxNjgwNjE1Nzk0fQ.IDKlHDVg1d7tAqb8eRiq90T52xnwVX9huDjpdLoJpqr4xlnTrFCdalxJBBHd9Cv39g2KPuJaCU21B59yNAyJP6bl5P8e9Ky-y8wOFcgHqcG5qXcNtxCS3imASCchRTtre8yp9AQGYkTIC0Jh6lWg0trdfO-_idKBsd5naJeaeYdeZGkpQ8D4dxn_odla67BO3y2mUtyE4gEbzyq6wTXDATN4ucM4Dyp3Wdk7YpYYuFN1g-sF6NFl4YqugQ4zk-pYYtPLlPgGiqi3_hO9kYbRDhNBtfbMx568m-CyM2tiOIkb4utPR20scSiRqnY2oxOcd5g9znvJOjtanHM3KVdj5g"
      }.to_json,
      headers: { "content-type" => "application/json; charset=utf-8" }
    )
    stub_request(:get, Addressable::Template.new("https://www.googleapis.com/oauth2/v3/userinfo{?alt}")).to_return(
      status: 200,
      body: { "sub" => "107403511037921355307",
              "name" => "Firstname Lastname",
              "given_name" => "Firstname",
              "family_name" => "Lastname",
              "picture" => "https://lh3.googleusercontent.com/a/AGNmyxZtDAl-mgOOCF_DCo-WWEct-LyVp7zGhXkfKR8r=s96-c",
              "email" => "email@dummy.com",
              "email_verified" => true,
              "locale" => "en-GB" }.to_json,
      headers: { "content-type" => "application/json; charset=utf-8" }
    )

    allow_any_instance_of(OmniAuth::Strategies::OpenIDConnect).to receive(:session) {
      { "omniauth.state" => auth_hash["state"] }
    }
  end

  it "redirects user without errors", :webmock, with_settings: {
    plugin_openproject_openid_connect: {
      "providers" => { "google" => { "identifier" => "identifier", "secret" => "secret" } }
    }
  } do
    response = get uri.to_s
    expect(response).to have_http_status(:found)
    expect(response.location).to eq("http://#{Setting.host_name}/two_factor_authentication/request")
  end
end
