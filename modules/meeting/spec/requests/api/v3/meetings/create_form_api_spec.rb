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
require "rack/test"

RSpec.describe API::V3::Meetings::CreateFormAPI, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  let(:user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:permissions) { %i[view_meetings create_meetings] }

  let(:path) { api_v3_paths.create_meeting_form }
  let(:parameters) { {} }

  before do
    login_as(user)
    post path, parameters.to_json
  end

  subject(:response) { last_response }

  describe "POST /api/v3/meetings/form" do
    it "returns 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "returns a form" do
      expect(response.body)
        .to be_json_eql("Form".to_json)
        .at_path("_type")
    end

    it "does not create a meeting" do
      expect(Meeting.count).to be 0
    end

    context "with empty parameters" do
      it "has validation errors" do
        expect(subject.body).to have_json_path("_embedded/validationErrors")
      end

      it "has a validation error on title" do
        expect(subject.body).to have_json_path("_embedded/validationErrors/title")
      end

      it "has no commit link" do
        expect(subject.body)
          .not_to have_json_path("_links/commit")
      end
    end

    context "with all minimum parameters" do
      let(:parameters) do
        {
          title: "New Meeting",
          startTime: "2026-06-01T10:00:00Z",
          _links: {
            project: {
              href: api_v3_paths.project(project.id)
            }
          }
        }
      end

      it "has 0 validation errors" do
        expect(subject.body).to have_json_size(0).at_path("_embedded/validationErrors")
      end

      it "has a commit link" do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.meetings.to_json)
          .at_path("_links/commit/href")
      end
    end

    context "with all parameters" do
      let(:parameters) do
        {
          title: "Full Meeting",
          location: "Room 42",
          startTime: "2026-06-01T14:00:00Z",
          duration: "PT2H",
          _links: {
            project: {
              href: api_v3_paths.project(project.id)
            }
          }
        }
      end

      it "has 0 validation errors" do
        expect(subject.body).to have_json_size(0).at_path("_embedded/validationErrors")
      end

      it "has the values prefilled in the payload", :aggregate_failures do
        expect(subject.body)
          .to be_json_eql("Full Meeting".to_json)
          .at_path("_embedded/payload/title")

        expect(subject.body)
          .to be_json_eql("Room 42".to_json)
          .at_path("_embedded/payload/location")

        expect(subject.body)
          .to be_json_eql(api_v3_paths.project(project.id).to_json)
          .at_path("_embedded/payload/_links/project/href")
      end

      it "has a commit link" do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.meetings.to_json)
          .at_path("_links/commit/href")
      end
    end

    context "without the necessary permission" do
      let(:permissions) { [:view_meetings] }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
