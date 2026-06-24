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

RSpec.describe API::V3::UserNonWorkingTimes::NonWorkingTimesByUserAPI do
  include API::V3::Utilities::PathHelper

  let(:admin_user) { create(:admin) }
  let(:target_user) { create(:user) }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  let!(:non_working_time_last_year) { create(:user_non_working_time, user: target_user, start_date: 1.year.ago.to_date) }
  let!(:non_working_time) { create(:user_non_working_time, user: target_user, start_date: Date.tomorrow) }

  describe "GET /api/v3/users/:user_id/non_working_times" do
    let(:path) { api_v3_paths.user_non_working_times(target_user.id) }

    context "with admin user" do
      current_user { admin_user }

      before { get path }

      it "returns 200 OK" do
        expect(last_response).to have_http_status(200)
      end

      it "returns a collection of non-working times for the current year" do
        expect(last_response.body).to be_json_eql("Collection".to_json).at_path("_type")
        expect(last_response.body).to be_json_eql(1.to_json).at_path("total")
      end
    end

    context "with own user" do
      let(:own_user) { create(:user) }
      let!(:own_time_last_year) { create(:user_non_working_time, user: own_user, start_date: 1.year.ago.to_date) }
      let!(:own_time) { create(:user_non_working_time, user: own_user, start_date: Date.tomorrow + 1.week) }

      current_user { own_user }

      before { get api_v3_paths.user_non_working_times(own_user.id) }

      it "returns 200 OK" do
        expect(last_response).to have_http_status(200)
      end

      it "returns only own records" do
        expect(last_response.body).to be_json_eql(1.to_json).at_path("total")
      end
    end

    context "with 'me' as the user ID" do
      let(:own_user) { create(:user) }
      let!(:own_time_last_year) { create(:user_non_working_time, user: own_user, start_date: 1.year.ago.to_date) }
      let!(:own_time) { create(:user_non_working_time, user: own_user, start_date: Date.tomorrow + 1.week) }

      current_user { own_user }

      before { get api_v3_paths.user_non_working_times("me") }

      it "returns 200 OK" do
        expect(last_response).to have_http_status(200)
      end

      it "returns the same records as using the numeric user ID" do
        expect(last_response.body).to be_json_eql(1.to_json).at_path("total")
      end
    end

    context "with regular user (no access to other users)" do
      current_user { create(:user) }

      before { get path }

      it "returns 404 since the user is not visible" do
        expect(last_response).to have_http_status(404)
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

    context "with year filter" do
      current_user { admin_user }

      it "returns only current year's records by default" do
        get path
        expect(last_response).to have_http_status(200)
        expect(last_response.body).to be_json_eql(1.to_json).at_path("total")
      end

      it "returns the requested year's records when year param is given" do
        get "#{path}?year=#{Date.current.year - 1}"
        expect(last_response).to have_http_status(200)
        expect(last_response.body).to be_json_eql(1.to_json).at_path("total")
        expect(last_response.body).to be_json_eql(non_working_time_last_year.start_date.iso8601.to_json)
                                        .at_path("_embedded/elements/0/startDate")
      end
    end

    it_behaves_like "handling anonymous user" do
      let(:path) { api_v3_paths.user_non_working_times(target_user.id) }

      before { get path }
    end
  end

  describe "POST /api/v3/users/:user_id/non_working_times" do
    let(:path) { api_v3_paths.user_non_working_times(target_user.id) }
    let(:start_date) { (Date.tomorrow + 1.month).iso8601 }
    let(:end_date) { (Date.tomorrow + 1.month + 4.days).iso8601 }
    let(:valid_params) { { startDate: start_date, endDate: end_date } }

    context "with admin user" do
      current_user { admin_user }

      before { post path, valid_params.to_json, headers }

      it "returns 201 Created" do
        expect(last_response).to have_http_status(201)
      end

      it "creates a non-working time for the target user" do
        parsed = JSON.parse(last_response.body)
        expect(parsed["_type"]).to eq("UserNonWorkingTime")
        expect(parsed["startDate"]).to eq(start_date)
        expect(parsed["endDate"]).to eq(end_date)
      end
    end

    context "with 'me' as the user ID with manage_own_working_times permission" do
      let(:own_user) { create(:user, global_permissions: [:manage_own_working_times]) }

      current_user { own_user }

      before { post api_v3_paths.user_non_working_times("me"), valid_params.to_json, headers }

      it "returns 201 Created" do
        expect(last_response).to have_http_status(201)
      end

      it "creates a non-working time for the current user" do
        parsed = JSON.parse(last_response.body)
        expect(parsed["_type"]).to eq("UserNonWorkingTime")
        expect(parsed["startDate"]).to eq(start_date)
        expect(parsed["endDate"]).to eq(end_date)
      end
    end

    context "with regular user targeting another user" do
      current_user { create(:user) }

      before { post path, valid_params.to_json, headers }

      it "returns 404 since the target user is not visible" do
        expect(last_response).to have_http_status(404)
      end
    end
  end

  describe "PATCH /api/v3/users/:user_id/non_working_times/:id" do
    let(:path) { api_v3_paths.user_non_working_time(target_user.id, non_working_time.id) }
    let(:new_start_date) { (Date.tomorrow + 2.months).iso8601 }
    let(:new_end_date) { (Date.tomorrow + 2.months + 4.days).iso8601 }
    let(:valid_params) { { startDate: new_start_date, endDate: new_end_date } }

    context "with admin user" do
      current_user { admin_user }

      before { patch path, valid_params.to_json, headers }

      it "returns 200 OK" do
        expect(last_response).to have_http_status(200)
      end

      it "updates the non-working time" do
        parsed = JSON.parse(last_response.body)
        expect(parsed["_type"]).to eq("UserNonWorkingTime")
        expect(parsed["startDate"]).to eq(new_start_date)
        expect(parsed["endDate"]).to eq(new_end_date)
      end
    end

    context "with 'me' as the user ID with manage_own_working_times permission" do
      let(:own_user) { create(:user, global_permissions: [:manage_own_working_times]) }
      let!(:own_time) { create(:user_non_working_time, user: own_user, start_date: Date.tomorrow + 2.weeks) }

      current_user { own_user }

      before { patch api_v3_paths.user_non_working_time("me", own_time.id), valid_params.to_json, headers }

      it "returns 200 OK" do
        expect(last_response).to have_http_status(200)
      end

      it "updates the non-working time for the current user" do
        parsed = JSON.parse(last_response.body)
        expect(parsed["_type"]).to eq("UserNonWorkingTime")
        expect(parsed["startDate"]).to eq(new_start_date)
        expect(parsed["endDate"]).to eq(new_end_date)
      end
    end

    context "with regular user (no access to other users)" do
      current_user { create(:user) }

      before { patch path, valid_params.to_json, headers }

      it "returns 404 since the target user is not visible" do
        expect(last_response).to have_http_status(404)
      end
    end
  end

  describe "DELETE /api/v3/users/:user_id/non_working_times/:id" do
    let(:path) { api_v3_paths.user_non_working_time(target_user.id, non_working_time.id) }

    context "with admin user" do
      current_user { admin_user }

      before { delete path }

      it "returns 204 No Content" do
        expect(last_response).to have_http_status(204)
      end

      it "deletes the record" do
        expect(UserNonWorkingTime.find_by(id: non_working_time.id)).to be_nil
      end
    end

    context "with 'me' as the user ID with manage_own_working_times permission" do
      let(:own_user) { create(:user, global_permissions: [:manage_own_working_times]) }
      let!(:own_time) { create(:user_non_working_time, user: own_user, start_date: Date.tomorrow + 2.weeks) }

      current_user { own_user }

      before { delete api_v3_paths.user_non_working_time("me", own_time.id) }

      it "returns 204 No Content" do
        expect(last_response).to have_http_status(204)
      end

      it "deletes the record" do
        expect(UserNonWorkingTime.find_by(id: own_time.id)).to be_nil
      end
    end

    context "with regular user (no access to other users)" do
      current_user { create(:user) }

      before { delete path }

      it "returns 404 since the target user is not visible" do
        expect(last_response).to have_http_status(404)
      end
    end
  end
end
