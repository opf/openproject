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

RSpec.describe "API v3 Cost Entry resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:cost_entry) { create(:cost_entry, project:) }
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { [:view_cost_entries] }
  let(:project) { create(:project) }

  subject(:response) { last_response }

  before do
    login_as(current_user)

    get get_path
  end

  describe "cost_entries/:id" do
    let(:get_path) { api_v3_paths.cost_entry cost_entry.id }

    context "user can see cost entries" do
      context "valid id" do
        it "returns HTTP 200" do
          expect(response.status).to be(200)
        end
      end

      context "invalid id" do
        let(:get_path) { api_v3_paths.cost_type "bogus" }

        it_behaves_like "not found"
      end
    end

    context "user can only see own cost entries" do
      let(:permissions) { [:view_own_cost_entries] }

      context "cost entry is not his own" do
        it_behaves_like "error response",
                        403,
                        "MissingPermission",
                        I18n.t("api_v3.errors.code_403")
      end

      context "cost entry is his own" do
        let(:cost_entry) { create(:cost_entry, project:, user: current_user) }

        it "returns HTTP 200" do
          expect(response.status).to be(200)
        end
      end
    end

    context "user has no cost entry permissions" do
      let(:permissions) { [] }

      describe "he can't even see own cost entries" do
        let(:cost_entry) { create(:cost_entry, project:, user: current_user) }

        it_behaves_like "error response",
                        403,
                        "MissingPermission",
                        I18n.t("api_v3.errors.code_403")
      end
    end
  end
end
