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

RSpec.describe "API v3 Root resource with the github integration extension", with_flag: { deploy_targets: true } do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:role) { create(:project_role, permissions: []) }
  let(:project) { create(:project, public: false) }

  before do
    # reset permissions cache, otherwise the introspection permissions enabled with the
    # deploy_targets feature flag won't be registered
    OpenProject::AccessControl.instance_variable_set(:@permissions, nil)
  end

  describe "#get" do
    let(:response) { last_response }
    let(:get_path) { api_v3_paths.root }

    subject { response.body }

    context "without introspection permission" do
      before do
        allow(User).to receive(:current).and_return(current_user)

        get get_path
      end

      it "responds with 200" do
        expect(response).to have_http_status(:ok)
      end

      it "does not include the core SHA in the res" do
        expect(subject).not_to have_json_path("coreSha")
      end
    end

    context "with introspection permission" do
      let(:current_user) { create(:user, global_permissions: [:introspection]) }
      let(:core_sha) { "b86f391bf02c345e934ca8a945d83fc82d2063ef" }

      before do
        allow(OpenProject::VERSION).to receive(:core_sha).and_return core_sha
        allow(User).to receive(:current).and_return(current_user)

        get get_path
      end

      it "responds with 200" do
        expect(response).to have_http_status(:ok)
      end

      it "does includes the core SHA in the response" do
        expect(subject).to be_json_eql(core_sha.to_json).at_path("coreSha")
      end
    end
  end
end
