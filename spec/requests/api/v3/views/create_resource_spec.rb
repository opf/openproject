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

require "spec_helper"

RSpec.describe API::V3::Views::ViewsAPI,
               "create",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:permitted_user) { create(:user) }
  shared_let(:role) { create(:project_role, permissions: %w[view_work_packages save_queries]) }
  shared_let(:project) do
    create(:project,
           members: { permitted_user => role })
  end
  shared_let(:private_user_query) do
    create(:query,
           project:,
           public: false,
           user: permitted_user)
  end

  let(:additional_setup) do
    # to be overwritten by some specs
  end

  let(:body) do
    {
      _links: {
        query: {
          href: api_v3_paths.query(private_user_query.id)
        }
      }
    }.to_json
  end

  let(:send_request) do
    post api_v3_paths.views_type("work_packages_table"), body
  end

  current_user { permitted_user }

  subject(:response) { last_response }

  before do
    additional_setup

    send_request
  end

  describe "POST /api/v3/views/work_packages_table" do
    context "with a user allowed to save the query" do
      it "returns 201 CREATED" do
        expect(response.status)
          .to eq(201)
      end

      it "returns the view" do
        expect(response.body)
          .to be_json_eql("Views::WorkPackagesTable".to_json)
                .at_path("_type")

        expect(response.body)
          .to be_json_eql(View.last.id.to_json)
                .at_path("id")
      end
    end

    context "with a user not allowed to see the query" do
      let(:additional_setup) do
        role.update_attribute(:permissions, [])
      end

      it "responds with 422 and explains the error" do
        expect(last_response).to have_http_status(:unprocessable_entity)

        expect(last_response.body)
          .to be_json_eql("Query does not exist.".to_json)
                .at_path("message")
      end
    end
  end

  describe "POST /api/v3/views/work_packages_calendar" do
    let(:send_request) do
      post api_v3_paths.views_type("work_packages_calendar"), body
    end

    context "with a user allowed to save the query and see the calendar" do
      let(:additional_setup) do
        role.update_attribute(:permissions, role.permissions + [:view_calendar])
      end

      it "returns 201 CREATED" do
        expect(response.status)
          .to eq(201)
      end

      it "returns the view" do
        expect(response.body)
          .to be_json_eql("Views::WorkPackagesCalendar".to_json)
                .at_path("_type")

        expect(response.body)
          .to be_json_eql(View.last.id.to_json)
                .at_path("id")
      end
    end

    context "with a user allowed to save the query but not to view calendars" do
      it_behaves_like "unauthorized access"
    end

    context "with a user not allowed to see the query" do
      let(:additional_setup) do
        role.update_attribute(:permissions, [])
      end

      it_behaves_like "unauthorized access"
    end
  end

  describe "POST /api/v3/views/bogus" do
    let(:send_request) do
      post api_v3_paths.views_type("bogus"), body
    end

    it_behaves_like "not found"
  end
end
