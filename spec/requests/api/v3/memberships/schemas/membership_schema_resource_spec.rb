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

RSpec.describe "API v3 Membership schema resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { create(:project) }
  let(:current_user) do
    create(:user, member_with_permissions: { project => permissions })
  end

  let(:permissions) { [:manage_members] }

  let(:path) { api_v3_paths.membership_schema }

  before do
    login_as(current_user)
  end

  subject(:response) { last_response }

  describe "#GET /memberships/schema" do
    before do
      get path
    end

    it "responds with 200 OK" do
      expect(subject.status).to eq(200)
    end

    it "returns a schema" do
      expect(subject.body)
        .to be_json_eql("Schema".to_json)
        .at_path "_type"
    end

    it "does not embed" do
      expect(subject.body)
        .not_to have_json_path("project/_links/allowedValues")
    end

    context "if lacking permissions" do
      let(:permissions) { [] }

      it "responds with 403" do
        expect(subject.status).to eq(403)
      end
    end
  end
end
