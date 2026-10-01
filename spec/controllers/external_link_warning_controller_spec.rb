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

RSpec.describe ExternalLinkWarningController do
  render_views

  describe "GET #show" do
    context "when capture is disabled" do
      before do
        allow(Setting).to receive(:capture_external_links?).and_return(false)
      end

      it "redirects directly to the external URL" do
        get :show, params: { url: "https://example.com" }

        expect(response).to redirect_to("https://example.com")
      end

      it "unescapes the URL parameter before redirecting" do
        encoded_url = CGI.escape("https://example.com/path?param=value")
        get :show, params: { url: encoded_url }

        expect(response).to redirect_to("https://example.com/path?param=value")
      end
    end

    context "when capture is enabled",
            with_ee: %i[capture_external_links],
            with_settings: { capture_external_links: true } do
      it "renders the warning page" do
        get :show, params: { url: "https://example.com" }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Leaving OpenProject")
        expect(response.body).to include("https://example.com")
      end

      it "unescapes the URL parameter" do
        encoded_url = CGI.escape("https://example.com/path?param=value")
        get :show, params: { url: encoded_url }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("https://example.com/path?param=value")
      end
    end

    context "with a percent-encoded unicode URL" do
      before do
        allow(Setting).to receive(:capture_external_links?).and_return(false)
      end

      it "handles URLs with percent-encoded UTF-8 characters" do
        encoded_url = CGI.escape("https://example.com?ünicode=1")
        get :show, params: { url: encoded_url }

        expect(response).to redirect_to("https://example.com?ünicode=1")
      end
    end

    context "when capture is enabled and login is required",
            with_ee: %i[capture_external_links],
            with_settings: { capture_external_links: true,
                             capture_external_links_require_login: true } do
      context "when logged in" do
        current_user { create(:user) }

        it "renders the warning page when logged in" do
          get :show, params: { url: "https://example.com" }

          expect(response).to have_http_status(:success)
          expect(response.body).to include("Leaving OpenProject")
          expect(response.body).to include("https://example.com")
        end
      end

      context "when not logged in" do
        it "redirects to login" do
          get :show, params: { url: "https://example.com" }
          back_url = external_redirect_url(url: "https://example.com")
          expect(response).to redirect_to(signin_path(back_url:))
        end
      end
    end

    context "with an invalid URL" do
      it "redirects to home when URL is blank" do
        get :show, params: { url: "" }

        expect(response).to redirect_to(home_path)
      end

      it "redirects to home when URL is missing" do
        get :show

        expect(response).to redirect_to(home_path)
      end

      it "redirects to home when URL is not a valid HTTP/HTTPS URL" do
        get :show, params: { url: "not-a-url" }

        expect(response).to redirect_to(home_path)
      end
    end
  end
end
