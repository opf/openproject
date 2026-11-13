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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Anonymous session", type: :rails_request, with_settings: { login_required?: false } do
  shared_let(:user) { create(:user) }

  let(:anonymous_sessions) { ActiveRecord::SessionStore::Session.where(user_id: nil) }

  def csrf_cookie_header
    Array(response.headers["Set-Cookie"])
      .find { |header| header.start_with?("#{Sessions::CsrfTokenCookieStore.cookie_name}=") }
  end

  it "is not stored for a request that does not render a form" do
    expect { get "/robots.txt" }.not_to change(anonymous_sessions, :count)
    expect(response).to have_http_status(:ok)
  end

  it "is not stored for the login page, which keeps its CSRF token in a cookie" do
    expect { get signin_path }.not_to change(anonymous_sessions, :count)
    expect(response).to have_http_status(:ok)
    expect(csrf_cookie_header).to include("path=/", "HttpOnly", "SameSite=Lax")
    expect(csrf_cookie_header).not_to include("secure")
  end

  it "allows to log in with the CSRF token from the login page" do
    get signin_path
    token = response.parsed_body.at_css("meta[name=csrf-token]")["content"]

    post signin_path, params: { username: user.login, password: "adminADMIN!", authenticity_token: token }
    follow_redirect! while response.redirect?

    expect(session[:user_id]).to eq(user.id)
  end

  it "rejects a login without a CSRF token" do
    get signin_path

    post signin_path, params: { username: user.login, password: "adminADMIN!" }

    expect(response).to have_http_status(422)
    expect(session[:user_id]).to be_nil
  end
end
