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

RSpec.describe "API v3 Root resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:role) { create(:project_role, permissions: []) }
  let(:project) { create(:project, public: false) }

  describe "#get" do
    let(:response) { last_response }
    let(:get_path) { api_v3_paths.root }

    subject { response.body }

    context "anonymous user" do
      before do
        get get_path
      end

      context "when login_required", with_settings: { login_required: true } do
        it_behaves_like "error response",
                        401,
                        "Unauthenticated",
                        I18n.t("api_v3.errors.code_401")
      end

      context "when not login_required", with_settings: { login_required: false } do
        it "responds with 200", :aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(subject).to have_json_path("instanceName")
        end
      end
    end

    context "logged in user" do
      before do
        allow(User).to receive(:current).and_return current_user

        get get_path
      end

      it "responds with 200" do
        expect(response).to have_http_status(:ok)
      end

      it "responds with a root representer" do
        expect(subject).to have_json_path("instanceName")
      end

      context "without the X-requested-with header", :skip_xhr_header do
        it "returns OK because GET requests are allowed" do
          expect(response).to have_http_status(:ok)
          expect(subject).to have_json_path("instanceName")
        end
      end

      context "with content-type application/hal+json" do
        before do
          header("Content-Type", "application/hal+json")
        end

        it "responds with 200" do
          get get_path
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
