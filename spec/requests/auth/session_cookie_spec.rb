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

RSpec.describe "Session cookie", type: :rails_request do
  it "is explicitly configured with SameSite=Lax" do
    expect(Rails.application.config.session_options[:same_site]).to eq(:lax)
  end

  it "sets SameSite=Lax on the HTTP-only cookie in the login response" do
    get signin_path

    cookie_name = OpenProject::Configuration["session_cookie_name"]
    cookie = Array(response.headers["Set-Cookie"]).find { |header| header.start_with?("#{cookie_name}=") }

    expect(response).to have_http_status(:ok)
    expect(cookie).to be_present
    expect(cookie).to include("SameSite=Lax", "HttpOnly")
  end
end
