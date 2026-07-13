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

RSpec.describe API::V3::UserWorkingHours::WorkingHoursByUserAPI do
  include API::V3::Utilities::PathHelper

  # Admin users can see all users and manage all working times.
  # Regular users with only manage_working_times can't access other users
  # via the user API because User.visible restricts visibility.
  let(:admin_user) { create(:admin) }
  let(:target_user) { create(:user) }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  let!(:working_hours) { create(:user_working_hours, user: target_user, valid_from: Date.yesterday) }
  let!(:future_record) { create(:user_working_hours, user: target_user, valid_from: Date.tomorrow) }

  describe "GET /api/v3/users/:user_id/working_hours" do
    let(:path) { api_v3_paths.user_working_hours(target_user.id) }

    context "with admin user (has manage_working_times and view_all_principals)" do
      current_user { admin_user }

      before { get path }

      it "returns 200 OK" do
        expect(last_response).to have_http_status(200)
      end

      it "returns a collection of working hours records" do
        expect(last_response.body).to be_json_eql("Collection".to_json).at_path("_type")
        expect(last_response.body).to be_json_eql(2.to_json).at_path("total")
      end
    end

    context "with manage_own_working_times viewing own records" do
      let(:own_user) { create(:user, global_permissions: [:manage_own_working_times]) }
      let!(:own_record) { create(:user_working_hours, user: own_user) }

      current_user { own_user }

      before { get api_v3_paths.user_working_hours(own_user.id) }

      it "returns 200 OK" do
        expect(last_response).to have_http_status(200)
      end

      it "returns the user's own working hours" do
        expect(last_response.body).to be_json_eql("Collection".to_json).at_path("_type")
        expect(last_response.body).to be_json_eql(1.to_json).at_path("total")
      end
    end

    context "with regular user viewing own records (no special permissions)" do
      current_user { target_user }

      before { get api_v3_paths.user_working_hours(target_user.id) }

      it "returns 200 with own records (visible scope returns own records)" do
        expect(last_response).to have_http_status(200)
        expect(last_response.body).to be_json_eql(2.to_json).at_path("total")
      end
    end

    context "with manage_own_working_times viewing another user's records" do
      let(:other_user) { create(:user, global_permissions: [:manage_own_working_times]) }

      current_user { other_user }

      before { get path }

      it "returns 404" do
        expect(last_response).to have_http_status(404)
      end
    end

    context "with 'me' as the user ID" do
      current_user { target_user }

      before { get api_v3_paths.user_working_hours("me") }

      it "returns 200 OK" do
        expect(last_response).to have_http_status(200)
      end

      it "returns the same records as using the numeric user ID" do
        expect(last_response.body).to be_json_eql(2.to_json).at_path("total")
      end
    end

    it_behaves_like "handling anonymous user" do
      let(:path) { api_v3_paths.user_working_hours(target_user.id) }

      before { get path }
    end
  end

  describe "POST /api/v3/users/:user_id/working_hours" do
    let(:path) { api_v3_paths.user_working_hours(target_user.id) }
    let(:valid_params) do
      {
        validFrom: Date.current.iso8601,
        mondayHours: 8,
        tuesdayHours: 8,
        wednesdayHours: 8,
        thursdayHours: 8,
        fridayHours: 8,
        saturdayHours: 0,
        sundayHours: 0,
        availabilityFactor: 100
      }
    end

    context "with admin user" do
      current_user { admin_user }

      before { post path, valid_params.to_json, headers }

      it "returns 201 Created" do
        expect(last_response).to have_http_status(201)
      end

      it "creates a working hours record for the target user" do
        parsed = JSON.parse(last_response.body)
        expect(parsed["_type"]).to eq("UserWorkingHours")
        expect(parsed["mondayHours"]).to eq(8.0)
      end
    end

    context "with own user but no manage_own_working_times permission" do
      current_user { target_user }

      before { post api_v3_paths.user_working_hours(target_user.id), valid_params.to_json, headers }

      it "returns 403 Forbidden" do
        expect(last_response).to have_http_status(403)
      end
    end

    context "with 'me' as the user ID with manage_own_working_times permission" do
      let(:own_user) { create(:user, global_permissions: [:manage_own_working_times]) }

      current_user { own_user }

      before { post api_v3_paths.user_working_hours("me"), valid_params.to_json, headers }

      it "returns 201 Created" do
        expect(last_response).to have_http_status(201)
      end

      it "creates a record for the current user" do
        parsed = JSON.parse(last_response.body)
        expect(parsed["_type"]).to eq("UserWorkingHours")
        expect(parsed["mondayHours"]).to eq(8.0)
      end
    end
  end

  describe "GET /api/v3/users/:user_id/working_hours/:id" do
    let(:path) { api_v3_paths.user_working_hours_record(target_user.id, working_hours.id) }

    context "with admin user" do
      current_user { admin_user }

      before { get path }

      it "returns 200 OK" do
        expect(last_response).to have_http_status(200)
      end

      it "returns the working hours record" do
        parsed = JSON.parse(last_response.body)
        expect(parsed["_type"]).to eq("UserWorkingHours")
        expect(parsed["id"]).to eq(working_hours.id)
        expect(parsed["mondayHours"]).to eq(8.0)
      end
    end

    context "with regular user (no access to other users)" do
      current_user { create(:user) }

      before { get path }

      it "returns 404 Not Found" do
        expect(last_response).to have_http_status(404)
      end
    end
  end

  describe "PATCH /api/v3/users/:user_id/working_hours/:id" do
    let(:path) { api_v3_paths.user_working_hours_record(target_user.id, future_record.id) }
    let(:params) { { mondayHours: 6 } }

    context "with admin user updating a future record" do
      current_user { admin_user }

      before { patch path, params.to_json, headers }

      it "returns 200 OK" do
        expect(last_response).to have_http_status(200)
      end

      it "updates the record" do
        parsed = JSON.parse(last_response.body)
        expect(parsed["mondayHours"]).to eq(6.0)
      end
    end

    context "when the record is already in effect (past valid_from)" do
      current_user { admin_user }

      before do
        patch api_v3_paths.user_working_hours_record(target_user.id, working_hours.id), params.to_json, headers
      end

      it "returns 422 Unprocessable Entity" do
        expect(last_response).to have_http_status(422)
      end
    end

    context "with regular user (no access to other users)" do
      current_user { create(:user) }

      before { patch path, params.to_json, headers }

      it "returns 404 Not Found" do
        expect(last_response).to have_http_status(404)
      end
    end
  end

  describe "DELETE /api/v3/users/:user_id/working_hours/:id" do
    let(:path) { api_v3_paths.user_working_hours_record(target_user.id, working_hours.id) }

    context "with admin user" do
      current_user { admin_user }

      before { delete path }

      it "returns 204 No Content" do
        expect(last_response).to have_http_status(204)
      end

      it "deletes the record" do
        expect(UserWorkingHours.find_by(id: working_hours.id)).to be_nil
      end
    end

    context "with regular user (no access to other users)" do
      current_user { create(:user) }

      before { delete path }

      it "returns 404 Not Found" do
        expect(last_response).to have_http_status(404)
      end
    end
  end
end
