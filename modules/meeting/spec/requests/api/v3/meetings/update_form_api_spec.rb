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

RSpec.describe API::V3::Meetings::UpdateFormAPI, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  let(:meeting) { create(:meeting, project:, author: user) }
  let(:user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:permissions) { %i[view_meetings edit_meetings] }

  let(:path) { api_v3_paths.meeting_form(meeting.id) }
  let(:parameters) do
    {
      title: "Updated Meeting Title"
    }
  end

  before do
    login_as(user)
    post path, parameters.to_json
  end

  subject(:response) { last_response }

  describe "POST /api/v3/meetings/:id/form" do
    it "returns 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "returns a form" do
      expect(response.body)
        .to be_json_eql("Form".to_json)
        .at_path("_type")
    end

    it "does not update the meeting" do
      expect(meeting.reload.title)
        .not_to eql "Updated Meeting Title"
    end

    context "with valid parameters" do
      it "has 0 validation errors" do
        expect(subject.body).to have_json_size(0).at_path("_embedded/validationErrors")
      end

      it "has the values prefilled in the payload" do
        expect(subject.body)
          .to be_json_eql("Updated Meeting Title".to_json)
          .at_path("_embedded/payload/title")
      end

      it "has a commit link" do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.meeting(meeting.id).to_json)
          .at_path("_links/commit/href")
      end
    end

    context "with nulling title" do
      let(:parameters) do
        { title: nil }
      end

      it "has validation errors" do
        expect(subject.body).to have_json_path("_embedded/validationErrors/title")
      end

      it "has no commit link" do
        expect(subject.body)
          .not_to have_json_path("_links/commit")
      end
    end

    context "without the necessary edit permission" do
      let(:permissions) { [:view_meetings] }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without the necessary view permission" do
      let(:permissions) { [] }

      it "returns 404" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
