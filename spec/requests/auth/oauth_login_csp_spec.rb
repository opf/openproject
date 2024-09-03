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

RSpec.describe "CSP appends on login form from oauth",
               type: :rails_request do
  let!(:redirect_uri) { "https://foobar.com" }
  let!(:oauth_app) { create(:oauth_application, redirect_uri:) }
  let(:oauth_path) do
    "/oauth/authorize?response_type=code&client_id=#{oauth_app.uid}&redirect_uri=#{CGI.escape(redirect_uri)}&scope=api_v3"
  end

  context "when login required", with_settings: { login_required: true } do
    it "appends given CSP appends from flash" do
      get oauth_path

      csp = response.headers["Content-Security-Policy"]
      expect(csp).to include "form-action 'self' https://foobar.com/;"

      location = response.headers["Location"]
      expect(location).to include("/login?back_url=#{CGI.escape(oauth_path)}")
    end
  end

  context "with redirect-uri being a custom scheme" do
    let(:redirect_uri) { "myscheme://custom-foobar" }

    it "appends given CSP appends from flash" do
      get oauth_path

      csp = response.headers["Content-Security-Policy"]
      expect(csp).to include "form-action 'self' myscheme:"
    end
  end
end
