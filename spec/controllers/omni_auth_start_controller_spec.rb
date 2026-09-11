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

RSpec.describe OmniAuthStartController do
  render_views

  describe "GET #show" do
    it "renders an auto-submitting POST form to the provider" do
      get :show, params: { provider: "developer" }

      expect(response).to render_template "account/omniauth_direct_login"
      expect(response.body).to include('action="/auth/developer"')
      expect(response.body).to include('method="post"')
      expect(response.body).to include('data-controller="omniauth-direct-login"')
    end

    it "returns 404 for an unknown provider" do
      get :show, params: { provider: "unknown" }

      expect(response).to have_http_status :not_found
    end

    context "when already logged in" do
      let(:user) { create(:user) }

      before { login_as user }

      it "redirects after login" do
        get :show, params: { provider: "developer" }

        expect(response).to redirect_to home_path
      end
    end
  end
end
