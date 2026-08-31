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

RSpec.describe "" do
  include CspHelper

  current_user { create(:user) }

  describe "GET /" do
    context "when collaborative_editing_hocuspocus_url is set as a valid URI" do
      it "responds with 200 and appends storage host to the connect-src CSP",
         with_settings: { collaborative_editing_hocuspocus_url: "wss://hocuspocus.local" } do
        get "/"

        expect(last_response).to have_http_status(200)
        csp = parse_csp(last_response.headers["Content-Security-Policy"])
        expect(csp["connect-src"]).to include("wss://hocuspocus.local")
      end
    end

    context "when collaborative_editing_hocuspocus_url is set to an invalid URI" do
      it "responds with 200 and logs the problem",
         with_settings: { collaborative_editing_hocuspocus_url: "://hocuspocus.local" } do
        allow(OpenProject.logger).to receive(:info)

        get "/"

        expect(last_response).to have_http_status(200)
        expect(OpenProject.logger).to have_received(:info) do |&blk|
          expect(blk.call).to eq "Setting.collaborative_editing_hocuspocus_url is set to an invalid URI: ://hocuspocus.local"
        end
      end
    end

    it "includes X-Content-Type-Options nosniff header to prevent content type sniffing" do
      get "/"

      expect(last_response).to have_http_status(200)
      expect(last_response.headers["X-Content-Type-Options"]).to eq "nosniff"
    end

    it "does not duplicate 'self' in font-src CSP directive" do
      get "/"

      csp = parse_csp(last_response.headers["Content-Security-Policy"])
      expect(csp["font-src"].count("'self'")).to eq(1)
    end

    it "includes 'self' in img-src CSP directive" do
      get "/"

      csp = parse_csp(last_response.headers["Content-Security-Policy"])
      expect(csp["img-src"]).to include("'self'")
    end

    it "does not duplicate 'self' in img-src CSP directive" do
      get "/"

      csp = parse_csp(last_response.headers["Content-Security-Policy"])
      expect(csp["img-src"].count("'self'")).to eq(1)
    end
  end
end
