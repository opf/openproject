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

RSpec.describe "CSRF token cookie", type: :rails_request, with_settings: { login_required?: false } do
  shared_let(:user) { create(:user) }

  let(:cookie_name) { Sessions::CsrfTokenCookieStore.cookie_name }

  def csrf_token
    response.parsed_body.at_css("meta[name=csrf-token]")["content"]
  end

  def csrf_cookie_header
    Array(response.headers["Set-Cookie"]).find { |header| header.start_with?("#{cookie_name}=") }
  end

  def log_in
    get signin_path
    post signin_path, params: { username: user.login, password: "adminADMIN!", authenticity_token: csrf_token }
    follow_redirect! while response.redirect?
  end

  def update_settings(token)
    patch "/my/settings", params: { authenticity_token: token }
  end

  it "accepts the token of the current session" do
    log_in

    update_settings(csrf_token)

    expect(response).not_to have_http_status(422)
  end

  it "rejects a token issued for another session" do
    log_in
    token = csrf_token
    cookie = cookies[cookie_name]

    get signout_path
    log_in
    cookies[cookie_name] = cookie
    update_settings(token)

    expect(response).to have_http_status(422)
  end

  it "rejects the token of the login page after the login" do
    get signin_path
    token = csrf_token
    post signin_path, params: { username: user.login, password: "adminADMIN!", authenticity_token: token }
    follow_redirect! while response.redirect?

    update_settings(token)

    expect(response).to have_http_status(422)
  end

  it "follows the relative URL root for its path", with_config: { rails_relative_url_root: "/openproject" } do
    get signin_path

    expect(csrf_cookie_header).to include("path=/openproject")
  end

  it "is secure without the SSL middleware when HTTPS is configured", with_config: { https: true, hsts: false } do
    https!
    get signin_path

    expect(csrf_cookie_header).to include("secure")
  end
end
