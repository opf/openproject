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

RSpec.describe "OmniAuth request phase", type: :rails_request do
  describe "GET /auth/developer" do
    it "does not start authentication" do
      get "/auth/developer"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /auth/developer without an authenticity token" do
    it "rejects the request" do
      post "/auth/developer"

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(signin_path)
    end
  end

  describe "POST /auth/developer with an authenticity token", :skip_csrf do
    it "starts the developer request phase" do
      post "/auth/developer"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("first_name")
    end
  end
end
