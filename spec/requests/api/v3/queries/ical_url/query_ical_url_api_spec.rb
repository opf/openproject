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

RSpec.describe "API v3 Query ICal Url" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  describe "#post queries/:id/ical_url" do
    let(:project) { create(:project) }
    let(:role) { create(:project_role, permissions:) }
    # TODO: check OpenProject::Configuration.ical_subscriptions_enabled configuration
    # :view_work_packages permission is mandatory, otherwise a 404 is returned.
    let(:permissions) { %i[view_work_packages share_calendars] }
    let(:user) do
      create(:user,
             member_with_roles: { project => role })
    end
    let(:query) { create(:query, project:, user:) }
    let(:path) { api_v3_paths.query_ical_url(query.id) }
    let(:params) { { token_name: "foo" } }

    before do
      allow(User)
        .to receive(:current)
        .and_return(user)

      header "Content-Type", "application/json"
      post path, params.to_json
    end

    shared_examples_for "success" do
      it "succeeds" do
        expect(last_response.status)
          .to eq(201)
      end

      it "returns the path pointing to self" do
        expect(last_response.body)
          .to be_json_eql(path.to_json)
          .at_path("_links/self/href")
      end

      it "returns the path pointing to the associated query" do
        expect(last_response.body)
          .to be_json_eql(api_v3_paths.query(query.id).to_json)
          .at_path("_links/query/href")
      end

      it "returns the tokenized, absolute url pointing to iCalendar endpoint" do
        json = JSON.parse(last_response.body)
        expect(json["_links"]["icalUrl"]["href"]).to include("http")
        expect(json["_links"]["icalUrl"]["href"]).to include(
          "projects/#{project.id}/calendars/#{query.id}/ical?ical_token="
        )
      end
    end

    context "when user has sufficient permissions and owns the query" do
      context "when icalendar sharing is enabled globally", with_settings: { ical_enabled: true } do
        it_behaves_like "success"
      end

      context "when icalendar sharing is disabled globally", with_settings: { ical_enabled: false } do
        it_behaves_like "unauthorized access"
      end
    end

    context "when user has sufficient permissions and tries to get the iCalendar url of the public query of another user" do
      let(:role_of_other_user) { create(:project_role, permissions: [:view_work_packages]) }
      let(:other_user) do
        create(:user,
               member_with_roles: { project => role_of_other_user })
      end
      let(:query) { create(:query, project:, user: other_user, public: true) }
      let(:path) { api_v3_paths.query_ical_url(query.id) }

      context "when icalendar sharing is enabled globally", with_settings: { ical_enabled: true } do
        it_behaves_like "success"
      end

      context "when icalendar sharing is disabled globally", with_settings: { ical_enabled: false } do
        it_behaves_like "unauthorized access"
      end
    end

    context "when user has no access to the associated project", with_settings: { ical_enabled: true } do
      let(:other_project) { create(:project) }
      let(:query) { create(:query, project: other_project, user:) }
      let(:path) { api_v3_paths.query_ical_url(query.id) }

      it_behaves_like "not found"
    end

    context "when user tries to get an iCalendar url from a private query of another user",
            with_settings: { ical_enabled: true } do
      let(:other_user) { create(:user) }
      let(:query) { create(:query, project:, user: other_user, public: false) }
      let(:path) { api_v3_paths.query_ical_url(query.id) }

      it_behaves_like "not found"
    end

    context "when user has insufficient permissions", with_settings: { ical_enabled: true } do
      # :view_work_packages permission is mandatory, otherwise a 404 is returned.
      let(:permissions) { [:view_work_packages] } # share_calendars is missing

      it_behaves_like "unauthorized access"
    end

    context "when query does not exist" do
      let(:path) { api_v3_paths.query_ical_url(query.id + 42) }

      it_behaves_like "not found"
    end
  end
end
