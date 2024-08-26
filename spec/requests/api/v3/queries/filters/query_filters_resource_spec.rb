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

RSpec.describe "API v3 Query Filter resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  describe "#get queries/filters/:id" do
    let(:path) { api_v3_paths.query_filter(filter_name) }
    let(:filter_name) { "assignee" }
    let(:project) { create(:project) }
    let(:role) { create(:project_role, permissions:) }
    let(:permissions) { [:view_work_packages] }
    let(:user) do
      create(:user,
             member_with_roles: { project => role })
    end

    before do
      allow(User)
        .to receive(:current)
        .and_return(user)

      get path
    end

    it "succeeds" do
      expect(last_response.status)
        .to eq(200)
    end

    it "returns the filter" do
      expect(last_response.body)
        .to be_json_eql(path.to_json)
        .at_path("_links/self/href")
    end

    context "user not allowed" do
      let(:permissions) { [] }

      it_behaves_like "unauthorized access"
    end

    context "non existing filter" do
      let(:filter_name) { "bogus" }

      it "returns 404" do
        expect(last_response.status)
          .to be(404)
      end
    end

    context "custom field filter" do
      let(:list_wp_custom_field) { create(:list_wp_custom_field) }
      let(:filter_name) { list_wp_custom_field.attribute_name(:camel_case) }

      it "succeeds" do
        expect(last_response.status)
          .to eq(200)
      end

      it "returns the filter" do
        expect(last_response.body)
          .to be_json_eql(path.to_json)
          .at_path("_links/self/href")
      end
    end
  end
end
