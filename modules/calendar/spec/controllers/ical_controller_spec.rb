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

RSpec.describe Calendar::ICalController do
  shared_let(:project) { create(:project) }

  shared_let(:work_package_with_due_date) do
    create(:work_package, project:,
                          due_date: Time.zone.today + 7.days)
  end
  shared_let(:work_package_with_start_date) do
    create(:work_package, project:,
                          start_date: Time.zone.today + 14.days)
  end
  shared_let(:work_package_with_start_and_due_date) do
    create(:work_package, project:,
                          start_date: Date.tomorrow,
                          due_date: Time.zone.today + 7.days)
  end
  shared_let(:work_package_with_due_date_far_in_past) do
    create(:work_package, project:,
                          due_date: Time.zone.today - 180.days)
  end
  shared_let(:work_package_with_due_date_far_in_future) do
    create(:work_package, project:,
                          due_date: Time.zone.today + 180.days)
  end
  shared_let(:work_packages) do
    [
      work_package_with_due_date,
      work_package_with_start_date,
      work_package_with_start_and_due_date,
      work_package_with_due_date_far_in_past,
      work_package_with_due_date_far_in_future
    ]
  end
  let(:user) do
    create(:user,
           member_with_permissions: { project => sufficient_permissions })
  end
  let(:sufficient_permissions) { %i[view_work_packages share_calendars] }
  let(:insufficient_permissions) { %i[view_work_packages] }
  let(:query) do
    create(:query,
           project:,
           user:,
           public: false) do |query|
      # add typical filter for calendar queries
      query.add_filter(:dates_interval, "<>d", [Time.zone.today, Time.zone.today + 30.days])
    end
  end
  let(:valid_ical_token_value) do
    Token::ICal.create_and_return_value(user, query, "Some Token Name")
  end

  # the ical urls are intended to be used without a logged in user from a calendar client app
  # before { login_as(user) }
  describe "#show" do
    shared_examples_for "success" do
      subject { response }

      it { is_expected.to be_successful }

      it "returns a valid ical file" do
        expected_file_name = "openproject_calendar_#{DateTime.now.to_i}.ics"
        expected_utf8_file_name = "UTF-8''#{expected_file_name}"

        expect(response.headers["Content-Type"]).to eq("text/calendar")
        expect(response.headers["Content-Disposition"]).to eq(
          "attachment; filename=\"#{expected_file_name}\"; filename*=#{expected_utf8_file_name}"
        )
        expect(subject.body).to match(/BEGIN:VCALENDAR/)
        expect(subject.body).to match(/END:VCALENDAR/)

        work_packages.each do |work_package|
          expect(subject.body).to include("#{work_package.id}@#{Setting.host_name}")
        end
      end
    end

    shared_examples_for "failure" do
      subject { response }

      it { is_expected.not_to be_successful }

      it "does not return a valid ical file" do
        expect(subject.body).not_to match(/BEGIN:VCALENDAR/)
        expect(subject.body).not_to match(/END:VCALENDAR/)

        work_packages.each do |work_package|
          expect(subject.body).not_to include("#{work_package.id}@#{Setting.host_name}")
        end
      end
    end

    context "with valid params and permissions when targeting own query" do
      before do
        get :show, params: {
          project_id: project.id,
          id: query.id,
          ical_token: valid_ical_token_value
        }
      end

      it_behaves_like "success"
    end

    context "with valid params and permissions with a query having a parent filter (bug #49726)" do
      before do
        User.execute_as(user) do
          parent_work_package = create(:work_package, project:, children: work_packages)
          query.add_filter(:parent, "=", [parent_work_package.id.to_s])
          query.save!
        end

        get :show, params: {
          project_id: project.id,
          id: query.id,
          ical_token: valid_ical_token_value
        }
      end

      it_behaves_like "success"
    end

    context "with valid params and permissions when targeting own query when globally disabled",
            with_settings: { ical_enabled: false } do
      before do
        get :show, params: {
          project_id: project.id,
          id: query.id,
          ical_token: valid_ical_token_value
        }
      end

      it_behaves_like "failure"
    end

    context "with valid params and permissions when targeting own query with login required set to `true`",
            with_settings: { login_required: true } do
      before do
        get :show, params: {
          project_id: project.id,
          id: query.id,
          ical_token: valid_ical_token_value
        }
      end

      it_behaves_like "success"
    end

    context "with valid params and permissions when targeting a public query of somebody else" do
      let(:user2) do
        create(:user,
               member_with_permissions: { project => sufficient_permissions })
      end
      let(:query2) do
        create(:query,
               project:,
               user: user2,
               public: true)
      end
      let(:valid_ical_token_value) do
        Token::ICal.create_and_return_value(user, query2, "Some Token Name")
      end

      before do
        get :show, params: {
          project_id: project.id,
          id: query2.id,
          ical_token: valid_ical_token_value
        }
      end

      it_behaves_like "success"
    end

    context "with valid params and permissions when targeting a public query of somebody else",
            with_settings: { ical_enabled: false } do
      let(:user2) do
        create(:user,
               member_with_permissions: { project => sufficient_permissions })
      end
      let(:query2) do
        create(:query,
               project:,
               user: user2,
               public: true)
      end
      let(:valid_ical_token_value) do
        Token::ICal.create_and_return_value(user, query2, "Some Token Name")
      end

      before do
        get :show, params: {
          project_id: project.id,
          id: query2.id,
          ical_token: valid_ical_token_value
        }
      end

      it_behaves_like "failure"
    end

    context "with valid params and permissions when targeting a public query of somebody else with login required set to `true`",
            with_settings: { login_required: true } do
      let(:user2) do
        create(:user,
               member_with_permissions: { project => sufficient_permissions })
      end
      let(:query2) do
        create(:query,
               project:,
               user: user2,
               public: true)
      end
      let(:valid_ical_token_value) do
        Token::ICal.create_and_return_value(user, query2, "Some Token Name")
      end

      before do
        get :show, params: {
          project_id: project.id,
          id: query2.id,
          ical_token: valid_ical_token_value
        }
      end

      it_behaves_like "success"
    end

    context "with valid params and permissions when targeting a private query of somebody else" do
      let(:user2) do
        create(:user,
               member_with_permissions: { project => sufficient_permissions })
      end
      let(:query2) do
        create(:query,
               project:,
               user: user2,
               public: false)
      end
      let(:valid_ical_token_value) do
        Token::ICal.create_and_return_value(user, query2, "Some Token Name")
      end

      before do
        get :show, params: {
          project_id: project.id,
          id: query2.id,
          ical_token: valid_ical_token_value
        }
      end

      it_behaves_like "failure"
    end

    context "with valid params and permissions when not part of the project (anymore)" do
      let(:project2) { create(:project) }
      let(:user) do
        create(:user,
               member_with_permissions: { project2 => sufficient_permissions })
      end

      before do
        get :show, params: {
          project_id: project.id,
          id: query.id,
          ical_token: valid_ical_token_value
        }
      end

      it_behaves_like "failure"
    end

    context "with valid params and missing permissions" do
      let(:user) do
        create(:user,
               member_with_permissions: { project => insufficient_permissions })
      end

      before do
        get :show, params: {
          project_id: project.id,
          id: query.id,
          ical_token: valid_ical_token_value
        }
      end

      it_behaves_like "failure"
    end

    context "with invalid token" do
      before do
        get :show, params: {
          project_id: project.id,
          id: query.id,
          ical_token: SecureRandom.hex
        }
      end

      it_behaves_like "failure"
    end

    context "with invalid query" do
      before do
        get :show, params: {
          project_id: project.id,
          id: SecureRandom.hex,
          ical_token: valid_ical_token_value
        }
      end

      it_behaves_like "failure"
    end

    context "with invalid project" do
      before do
        get :show, params: {
          project_id: SecureRandom.hex,
          id: query.id,
          ical_token: valid_ical_token_value
        }
      end

      # TODO: the project id is actually irrelevant - the query id is enough
      # should the project id still be used in the ical url anyways?
      it_behaves_like "success"
    end

    context "with invalid project", with_settings: { ical_enabled: false } do
      before do
        get :show, params: {
          project_id: SecureRandom.hex,
          id: query.id,
          ical_token: valid_ical_token_value
        }
      end

      # TODO: the project id is actually irrelevant - the query id is enough
      # should the project id still be used in the ical url anyways?
      it_behaves_like "failure"
    end
  end
end
